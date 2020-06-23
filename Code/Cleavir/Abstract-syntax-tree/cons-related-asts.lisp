(cl:in-package #:cleavir-ast)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Class CAR-AST.
;;;
;;; This AST can be used to implement the function CAR.  However, it
;;; does not correspond exactly to the function CAR, because the value
;;; of the single child must be a CONS cell. 

(defclass car-ast (one-value-ast-mixin ast)
  ((%cons-ast :initarg :cons-ast :reader cons-ast)))

(defun make-car-ast (cons-ast &key origin (policy *policy*))
  (make-instance 'car-ast
    :origin origin :policy policy
    :cons-ast cons-ast))

(cleavir-io:define-save-info car-ast
  (:cons-ast cons-ast))

(defmethod children ((ast car-ast))
  (list (cons-ast ast)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Class CDR-AST.
;;;
;;; This AST can be used to implement the function CDR.  However, it
;;; does not correspond exactly to the function CDR, because the value
;;; of the single child must be a CONS cell. 

(defclass cdr-ast (one-value-ast-mixin ast)
  ((%cons-ast :initarg :cons-ast :reader cons-ast)))

(defun make-cdr-ast (cons-ast &key origin (policy *policy*))
  (make-instance 'cdr-ast
    :origin origin :policy policy
    :cons-ast cons-ast))

(cleavir-io:define-save-info cdr-ast
  (:cons-ast cons-ast))

(defmethod children ((ast cdr-ast))
  (list (cons-ast ast)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Class RPLACA-AST.
;;;
;;; This AST can be used to implement the function RPLACA and the
;;; function (SETF CAR) in implementations where it is a function.
;;; This AST differs from the function RPLACA in that it does not
;;; generate any value.  An attempt to compile this AST in a context
;;; where a value is needed will result in an error being signaled.

(defclass rplaca-ast (no-value-ast-mixin ast)
  ((%cons-ast :initarg :cons-ast :reader cons-ast)
   (%object-ast :initarg :object-ast :reader object-ast)))

(defun make-rplaca-ast (cons-ast object-ast &key origin (policy *policy*))
  (make-instance 'rplaca-ast
    :origin origin :policy policy
    :cons-ast cons-ast
    :object-ast object-ast))

(cleavir-io:define-save-info rplaca-ast
  (:cons-ast cons-ast)
  (:object-ast object-ast))

(defmethod children ((ast rplaca-ast))
  (list (cons-ast ast) (object-ast ast)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Class RPLACD-AST.
;;;
;;; This AST can be used to implement the function RPLACD and the
;;; function (SETF CDR) in implementations where it is a function.
;;; This AST differs from the function RPLACD in that it does not
;;; generate any value.  An attempt to compile this AST in a context
;;; where a value is needed will result in an error being signaled.

(defclass rplacd-ast (no-value-ast-mixin ast)
  ((%cons-ast :initarg :cons-ast :reader cons-ast)
   (%object-ast :initarg :object-ast :reader object-ast)))

(defun make-rplacd-ast (cons-ast object-ast &key origin (policy *policy*))
  (make-instance 'rplacd-ast
    :origin origin :policy policy
    :cons-ast cons-ast
    :object-ast object-ast))

(cleavir-io:define-save-info rplacd-ast
  (:cons-ast cons-ast)
  (:object-ast object-ast))

(defmethod children ((ast rplacd-ast))
  (list (cons-ast ast) (object-ast ast)))
