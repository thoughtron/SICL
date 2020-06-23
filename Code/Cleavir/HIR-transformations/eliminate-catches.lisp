(in-package #:cleavir-hir-transformations)

;;;; Eliminates CATCH-INSTRUCTIONS with unused continuations.
;;;; Because they have multiple successors, this is not suitable
;;;; for inclusion in the general remove-useless-instructions.

(defun dead-catch-p (instruction)
  (and (typep instruction 'cleavir-ir:catch-instruction)
       (let ((cont (first (cleavir-ir:outputs instruction))))
         (null (cleavir-ir:using-instructions cont)))))

(defun eliminate-catches (initial-instruction)
  (let ((death nil))
    (cleavir-ir:map-instructions-arbitrary-order
     (lambda (instruction)
       ;; Update instruction dynenvs by zooming up the nesting until a
       ;; live dynenv is reached.
       (do* ((dynenv (cleavir-ir:dynamic-environment instruction)
                     (cleavir-ir:dynamic-environment dynenv-definer))
             (dynenv-definer (first (cleavir-ir:defining-instructions dynenv))
                             (first (cleavir-ir:defining-instructions dynenv))))
           ((not (dead-catch-p dynenv-definer))
            (setf (cleavir-ir:dynamic-environment instruction) dynenv)))
       (when (dead-catch-p instruction)
         (push instruction death)))
     initial-instruction)
    (dolist (catch death)
      ;; Modify the flow graph.
      (cleavir-ir:bypass-instruction (first (cleavir-ir:successors catch)) catch))
    death))
