(cl:in-package #:cleavir-partial-inlining)

;;; Remvoe an enter instruction from the list of predecessors of its successors.
(defun disconnect-predecessor (instruction)
  (dolist (successor (cleavir-ir:successors instruction))
    (setf (cleavir-ir:predecessors successor)
          (delete instruction (cleavir-ir:predecessors successor)))))

(defun attach-predecessor (instruction)
  (dolist (successor (cleavir-ir:successors instruction))
    (push instruction (cleavir-ir:predecessors successor))))

(defmethod inline-function (initial call enter mapping)
  (let* ((*original-enter-instruction* enter)
         (*instruction-mapping* (make-hash-table :test #'eq))
         ;; Used for catch/unwind (local-catch-p)
         (*target-enter-instruction* (instruction-owner call))
         (initial-environment (cleavir-ir:parameters enter))
         ;; *policy* is bound closely for these bindings to make especially sure
         ;; that inlined instructions have the policy of the source function,
         ;; rather than the call.
         (call-arguments
           (loop with cleavir-ir:*origin* = (cleavir-ir:origin call)
                 with cleavir-ir:*policy* = (cleavir-ir:policy call)
                 with cleavir-ir:*dynamic-environment*
                   = (cleavir-ir:dynamic-environment call)
                 for location in initial-environment
                 for arg in (rest (cleavir-ir:inputs call))
                 for temp = (cleavir-ir:new-temporary)
                 for assign = (cleavir-ir:make-assignment-instruction arg temp)
                 do (when (cleavir-ir:using-instructions location)
                      (let ((binding-assign (first (cleavir-ir:using-instructions location))))
                        ;; Don't have to push these onto the binding
                        ;; assignment list, because only the clones
                        ;; will end up needing cells.
                        (change-class binding-assign 'binding-assignment-instruction)))
                    (cleavir-ir:insert-instruction-before assign call)
                    (setf (instruction-owner assign) *target-enter-instruction*)
                    (add-to-mapping mapping location temp)
                    (setf (location-owner temp) *target-enter-instruction*)
                 collect temp))
         (dynenv (cleavir-ir:dynamic-environment call))
         (function-temp (cleavir-ir:new-temporary))
         ;; This is used by the "partial" enter, but not actually connected.
         (fake-dynenv (cleavir-ir:new-temporary))
         (new-enter (cleavir-ir:clone-instruction enter
                      :dynamic-environment fake-dynenv))
         (enc (let ((cleavir-ir:*origin* (cleavir-ir:origin call))
                    (cleavir-ir:*policy* (cleavir-ir:policy call))
                    (cleavir-ir:*dynamic-environment* dynenv))
                (cleavir-ir:make-enclose-instruction function-temp call new-enter))))
    ;; Map the old inner dynenv to the outer dynenv.
    (add-to-mapping mapping
                    (cleavir-ir:dynamic-environment enter)
                    (cleavir-ir:dynamic-environment call))
    ;; the new ENTER shares policy and successor, but has no parameters.
    (setf (cleavir-ir:lambda-list new-enter) '()
          ;; the temporary is the closure variable.
          (cleavir-ir:outputs new-enter) (list (cleavir-ir:new-temporary) fake-dynenv))
    ;; Ensure that the enc's successor doens't contain enc as a
    ;; predecessor, since this is outdated information.
    (disconnect-predecessor enc)
    (cleavir-ir:insert-instruction-before enc call)
    (setf (cleavir-ir:inputs call) (cons function-temp call-arguments))
    ;; If we're fully inlining a function, we want to use the call instruction's
    ;; output instead of the callee's return values.
    ;; FIXME: Not sure what to do if we're not fully inlining.
    (loop with caller-values = (first (cleavir-ir:outputs call))
          for return in (cleavir-ir:local-instructions-of-type
                         enter 'cleavir-ir:return-instruction)
          for input = (first (cleavir-ir:inputs return))
          do (add-to-mapping mapping input caller-values))
    ;; Do the actual inlining.
    ;; FIXME: Once an inlining stops, all remaining residual functions should have
    ;; any variables live at that point added as inputs, etc.
    (let ((worklist (list (make-instance 'worklist-item
                            :enclose-instruction enc
                            :call-instruction call
                            :enter-instruction new-enter
                            :mapping mapping))))
      (loop until (null worklist)
            do (let* ((item (pop worklist))
                      (enter (enter-instruction item))
                      (successor (first (cleavir-ir:successors enter))))
                 (setf worklist
                       (append (inline-one-instruction
                                (enclose-instruction item)
                                (call-instruction item)
                                enter
                                successor
                                (mapping item))
                               worklist)))))))
