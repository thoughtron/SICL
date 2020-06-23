(cl:in-package #:sicl-clos)

;;;; This file contains the support code for the generic functions
;;;; ADD-METHOD and REMOVE-METHOD.
;;;;
;;;; In this file, there are no definitions of generic functions, nor
;;;; of any methods.

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Utilities

(defun compute-specializer-profile (existing-profile specializers)
  (loop with environment = (sicl-genv:global-environment)
        with class-t = (find-class 't)
        for specializer in specializers
        for p in existing-profile
        collect (if (eq specializer class-t) p t)))

;;; Update the specializer profile of a generic function according to
;;; a list of specializers of a method.
(defun update-specializer-profile (generic-function specializers)
  (setf (specializer-profile generic-function)
        (compute-specializer-profile
         (specializer-profile generic-function) specializers)))

;;; Compute a completely new specializer profile for a generic
;;; function.
(defun compute-and-set-specializer-profile (generic-function)
  ;; Keep the length of the profile, but with all elements NIL.
  (setf (specializer-profile generic-function)
        (make-list (length (specializer-profile generic-function))))
  (loop for method in (generic-function-methods generic-function)
        for specializers = (method-specializers method)
        do (update-specializer-profile generic-function specializers)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Generic function ADD-METHOD.
;;;
;;; For the specification of this generic function, see
;;; http://metamodular.com/CLOS-MOP/add-method.html
;;;
;;; The specification includes a single method on this generic
;;; function, specialized for STANDARD-GENERIC-FUNCTION and
;;; STANDARD-METHOD.  The default action below is valid for that
;;; method.

(defun applicable (class-cache profile method)
  (let* ((env (sicl-genv:global-environment))
         (class-t (find-class 't))
         (classes (loop with remaining = class-cache
                        for p in profile
                        collect (if p (pop remaining) class-t))))
    (maybe-applicable-p method classes)))

(defun add-method-default (generic-function method)
  (unless (null (method-generic-function method))
    (error 'method-already-associated-with-a-generic-function
           :method-to-add method
           :its-generic-function (method-generic-function method)))
  ;; FIXME: check that the lambda list are congruent
  ;;
  ;; See if GENERIC-FUNCTION has a method with the same specializers
  ;; and the same qualifiers as METHOD.  If such a method exists, it
  ;; must be removed before this method is added.
  (let ((method-to-remove
          (find-if (lambda (existing-method)
                     ;; They must have the same qualifiers
                     ;; and the same specializers.
                     (and (null (set-exclusive-or
                                 (method-qualifiers method)
                                 (method-qualifiers existing-method)))
                          (equal (method-specializers method)
                                 (method-specializers existing-method))))
                   (generic-function-methods generic-function))))
    (unless (null method-to-remove)
      (remove-method generic-function method-to-remove)))
  ;; Add this method to the set of methods of this generic function.
  (push method (generic-function-methods generic-function))
  (let* ((profile (specializer-profile generic-function))
         (specializers (method-specializers method))
         (new-profile (compute-specializer-profile profile specializers)))
    (setf (specializer-profile generic-function) new-profile)
    (unless (equal profile new-profile)
      (setf (call-history generic-function) '())))
  ;; Associate GENERIC-FUNCTION with METHOD.
  (setf (method-generic-function method) generic-function)
  ;; Call ADD-DIRECT-METHOD for each of the specializers of METHOD.
  (loop for specializer in (method-specializers method)
        do (add-direct-method specializer method))
  ;; Remove entries in the call history for which the new method is
  ;; applicable.
  (setf (call-history generic-function)
        (loop with profile = (specializer-profile generic-function)
              for cache in (call-history generic-function)
              for class-cache = (class-cache cache)
              unless (applicable class-cache profile method)
                collect cache))
  ;; Invalidate the current discriminating function so that it will be
  ;; recomputed next time the generic function is called.
  (invalidate-discriminating-function generic-function)
  ;; Update the dependents of GENERIC-FUNCTION.
  (map-dependents generic-function
                  (lambda (dependent)
                    (update-dependent generic-function
                                      dependent
                                      'add-method
                                      method))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Generic function REMOVE-METHOD.
;;;
;;; For the specification of this generic function, see
;;; http://metamodular.com/CLOS-MOP/remove-method.html
;;;
;;; The specification includes a single method on this generic
;;; function, specialized for STANDARD-GENERIC-FUNCTION and
;;; STANDARD-METHOD.  The default action below is valid for that
;;; method.

(defun remove-method-default (generic-function method)
  ;; Remove entries in the call history for which the method is
  ;; applicable.
  (setf (call-history generic-function)
        (loop with profile = (specializer-profile generic-function)
              for cache in (call-history generic-function)
              for class-cache = (class-cache cache)
              unless (applicable class-cache profile method)
                collect cache))
  ;; Remove METHOD from the methods of GENERIC-FUNCTION.
  (setf (generic-function-methods generic-function)
        (remove method (generic-function-methods generic-function)))
  ;; Compute a new specializer profile for the generic function.
  (compute-and-set-specializer-profile generic-function)
  ;; Call REMOVE-DIRECT-METHOD for each of the specializers of METHOD.
  (loop for specializer in (method-specializers method)
        do (remove-direct-method specializer method))
  ;; Disassociate GENERIC-FUNCTION from METHOD.
  (setf (method-generic-function method) nil)
  ;; Invalidate the current discriminating function so that it will be
  ;; recomputed next time the generic function is called.
  (invalidate-discriminating-function generic-function)
  ;; Update the dependents of GENERIC-FUNCTION.
  (map-dependents generic-function
                  (lambda (dependent)
                    (update-dependent generic-function
                                      dependent
                                      'remove-method
                                      method))))
