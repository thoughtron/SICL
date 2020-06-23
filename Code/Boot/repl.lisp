(cl:in-package #:sicl-boot)

(defun repl (e5)
  (loop with client = (make-instance 'sicl-boot:client)
        do (format t "SICL> ")
           (finish-output *standard-output*)
           (let* ((form (eclector.reader:read))
                  (values (multiple-value-list (cleavir-cst-to-ast:eval client form e5))))
             (loop for value in values
                   do (print value))
             (format t "~%")
             (finish-output *standard-output*))))
