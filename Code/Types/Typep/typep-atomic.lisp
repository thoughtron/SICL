(cl:in-package #:sicl-type)

(defun typep-atomic (object type-specifier)
  (let ((global-environment (sicl-genv:global-environment)))
    (cond ((symbolp type-specifier)
           (case type-specifier
             (atom
              (not (consp object)))
             ((base-char standard-char)
              (characterp object))
             (keyword
              (and (symbolp object)
                   (eq (symbol-package object)
                       (find-package '#:keyword))))
             (simple-array
              (typep object 'array))
             (class
              (let ((object-class (class-of object)))
                ;; RETURN true if and only if the class named CLASS is a
                ;; member of the class precedence list of the class of
                ;; the object.
                (if (member (sicl-genv:find-class 'class global-environment)
                            (sicl-clos:class-precedence-list object-class))
                    t nil)))
             (otherwise
              (let ((expander (sicl-genv:type-expander type-specifier global-environment))
                    (type-class (sicl-genv:find-class type-specifier global-environment)))
                (cond ((not (null expander))
                       ;; We found an expander.  Expand TYPE-SPECIFIER and call
                       ;; TYPEP recursively with the expanded type specifier.
                       (typep object (funcall expander type-specifier)))
                      ((not (null type-class))
                       ;; TYPE-SPECIFIER is the name of a class.
                       (typep-atomic object type-class))
                      (t
                       ;; TYPE-SPECIFIER has no expander associated with it and it
                       ;; is not also a class.  Furthermore, there was no method
                       ;; on TYPEP-ATOMIC specialized to the name of the type.
                       ;; This can only mean that TYPE-SPECIFIER is not a valid
                       ;; type specifier.
                       (error "unknown type ~s" type-specifier)))))))
          ((typep type-specifier 'class)
           (let ((object-class (class-of object)))
             ;; RETURN true if and only if TYPE-SPECIFIER is a member of the
             ;; class precedence list of the class of the object.
             (if (member type-specifier (sicl-clos:class-precedence-list object-class))
                 t nil)))
          (t
           (error "Invalid type specifier ~s" type-specifier)))))
