(cl:in-package #:cleavir-cst-to-ast)

;;; ENVIRONMENT is an environment that is known to contain information
;;; about the variable VARIABLE, but we don't know whether it is
;;; special or lexical.  VALUE-AST is an AST that computes the value
;;; to be given to VARIABLE.  BODY-FUNCTION is a thunk.  The body code
;;; generated by a call to BODY-FUNCTION represents the computation to
;;; take place after the variable has been given its value.  If the
;;; variable is special, this function creates a BIND-AST with the
;;; body code generated by the call to BODY-FUNCTION in it.  If the
;;; variable is lexical, this function creates a PROGN-AST with two
;;; ASTs in it.  The first one is a SETQ-AST that assigns the value to
;;; the variable, and the second one is the body generated by the call
;;; to BODY-FUNCTION.

(defun set-or-bind-variable (client variable-cst value-ast body-function environment)
  (let ((info (trucler:describe-variable client environment (cst:raw variable-cst))))
    (assert (not (null info)))
    (if (typep info 'trucler:special-variable-description)
        (convert-special-binding
         client variable-cst value-ast body-function environment)
        (cleavir-ast:make-ast 'cleavir-ast:progn-ast
         :form-asts (list (cleavir-ast:make-ast 'cleavir-ast:setq-ast
                            :lhs-ast (trucler:identity info)
                            :value-ast value-ast)
                     (funcall body-function))))))
