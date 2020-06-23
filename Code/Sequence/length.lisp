(cl:in-package #:sicl-sequence)

(defmethod length ((list list))
  (declare (method-properties inlineable))
  (labels ((len (rest counter)
             (if (atom rest)
                 (if (null rest)
                     counter
                     (error 'must-be-proper-list
                            :datum list))
                 (len (cdr rest) (1+ counter)))))
    (len list 0)))

(seal-domain #'length '(list))

(replicate-for-each-vector-class #1=#:vector-class
  (defmethod length ((vector #1#))
    (declare (method-properties inlineable))
    (cl:length vector)))

(seal-domain #'length '(vector))
