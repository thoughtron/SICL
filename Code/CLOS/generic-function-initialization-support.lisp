(in-package #:sicl-clos)

(defun set-lambda-list-and-argument-precedence-order
    (generic-function
     lambda-list
     lambda-list-p
     argument-precedence-order
     argument-precedence-order-p)
  (when (and argument-precedence-order-p
	     (not lambda-list-p))
    (error "when argument precedence order appears, so must lambda list"))
  (unless (proper-list-p argument-precedence-order)
    (error "argument-precedence-order must be a proper list"))
  (when lambda-list-p
    (let ((parsed-lambda-list
	    (parse-generic-function-lambda-list lambda-list)))
      (unless argument-precedence-order-p
	(setf argument-precedence-order
	      (required parsed-lambda-list)))
      (setf (specializer-profile generic-function)
	    (make-list (length (required parsed-lambda-list))
		       :initial-element nil))
      (setf (gf-lambda-list generic-function)
	    lambda-list)
      (setf (gf-argument-precedence-order generic-function)
	    argument-precedence-order))))

(defun check-documentation (documentation)
  (unless (or (null documentation) (stringp documentation))
    (error "documentation must be NIL or a string")))

;;; FIXME: check the syntax of each declaration. 
(defun check-declarations (declarations)
  (unless (proper-list-p declarations)
    (error "declarations must be a proper list")))

(defun set-method-combination (generic-function method-combination)
  ;; FIXME: check that method-combination is a method-combination metaobject
  (setf (gf-method-combination generic-function)
	method-combination))

(defun set-method-class (generic-function method-class)
  ;; FIXME: check that the method-class is a subclss of METHOD.
  (setf (gf-method-class generic-function)
	method-class))

(defun initialize-instance-after-standard-generic-function-default
    (generic-function
     &key
       (lambda-list nil lambda-list-p)
       (argument-precedence-order nil argument-precedence-order-p)
       method-combination
       (method-class (find-class 'standard-method))
       (name nil)
     &allow-other-keys)
  ;; FIXME: handle different method combinations.
  (declare (ignore method-combination))
  (set-method-class generic-function method-class)
  (set-lambda-list-and-argument-precedence-order
   generic-function
   lambda-list
   lambda-list-p
   argument-precedence-order
   argument-precedence-order-p)
  (let ((fun (compute-discriminating-function generic-function)))
    (setf (discriminating-function generic-function) fun)
    (unless (null name)
      (set-funcallable-instance-function generic-function fun))))

(defun reinitialize-instance-after-standard-generic-function-default
    (generic-function
     &rest initargs
     &key
       (lambda-list nil lambda-list-p)
       (argument-precedence-order nil argument-precedence-order-p)
       method-combination
       (method-class nil method-class-p)
     &allow-other-keys)
  ;; FIXME: handle different method combinations.
  (declare (ignore method-combination))
  (when method-class-p
    (set-method-class generic-function method-class))
  (set-lambda-list-and-argument-precedence-order
   generic-function
   lambda-list
   lambda-list-p
   argument-precedence-order
   argument-precedence-order-p)
  (map-dependents
   generic-function
   (lambda (dependent)
     (apply #'update-dependent generic-function dependent initargs))))
