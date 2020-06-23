(in-package #:cleavir-hir-transformations)

;;; Copy propagate the instruction and return the old defining
;;; instructions of the input for the sake of incremental analysis.
(defgeneric copy-propagate-instruction (instruction))

(defmethod copy-propagate-instruction (instruction))

(defmethod copy-propagate-instruction ((assignment cleavir-ir:assignment-instruction))
  (let ((input (first (cleavir-ir:inputs assignment)))
        (output (first (cleavir-ir:outputs assignment))))
    ;; Without reaching definitions, the output and input must *both*
    ;; have only one definition, the initial one.
    (when (and (null (rest (cleavir-ir:defining-instructions input)))
               (null (rest (cleavir-ir:defining-instructions output))))
      ;; Some assignments are totally useless.
      (if (eq input output)
          (cleavir-ir:delete-instruction assignment)
          (prog1 (cleavir-ir:using-instructions output)
            (cleavir-ir:replace-datum input output)
            (cleavir-ir:delete-instruction assignment))))))

;;; A lightweight copy propagation utility to get rid of pesky
;;; assignments blocking optimizations.  Copy propagate forward one
;;; datum.
(defun copy-propagate-1 (datum)
  (let ((worklist (cleavir-ir:using-instructions datum)))
    (loop (unless worklist
            (return))
          (let ((use (pop worklist)))
            (dolist (use (copy-propagate-instruction use))
              (push use worklist))))))
