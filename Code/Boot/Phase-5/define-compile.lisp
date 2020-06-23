(cl:in-package #:sicl-boot-phase-5)

(defun define-compile (e4 e5)
  (setf (sicl-genv:fdefinition 'compile e5)
        (lambda (name &optional definition)
          (assert (null name))
          (assert (not (null definition)))
          (let* ((cst (cst:cst-from-expression definition))
                 (client (make-instance 'sicl-boot:client))
                 (ast (let ((cleavir-cst-to-ast::*origin* nil))
                        (cleavir-cst-to-ast:cst-to-ast client cst e5)))
                 (code-object (sicl-compiler:compile-ast client ast)))
            (sicl-boot:tie-code-object client code-object e5 e4)))))
