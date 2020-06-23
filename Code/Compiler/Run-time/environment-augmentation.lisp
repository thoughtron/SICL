(cl:in-package #:sicl-run-time)

(defun augment-with-block/tagbody-entry ()
  (cons (make-instance 'block/tagbody-entry
          :stack-pointer (sicl-primop:caller-stack-pointer)
          :frame-pointer (sicl-primop:caller-frame-pointer)
          :continuation (list nil))
        (sicl-primop:dynamic-environment)))

(defun augment-with-special-variable-entry (name value)
  (cons (make-instance 'special-variable-entry
          :name name
          :value value)
        (sicl-primop:dynamic-environment)))
