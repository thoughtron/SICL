(cl:in-package #:sicl-sequence)

(defun make-sequence (result-type length &key (initial-element nil initial-element-p))
  (with-reified-result-type (prototype result-type)
    (if (not initial-element-p)
        (make-sequence-like prototype length)
        (make-sequence-like prototype length :initial-element initial-element))))

(define-compiler-macro make-sequence
    (&whole form result-type length &rest rest &environment env)
  (if (and (constantp result-type)
           (or (null rest)
               (and (eql (first rest) :initial-element)
                    (= 2 (length rest)))))
      (let ((type (eval result-type)))
        `(the ,type (make-sequence-like ',(reify-sequence-type-specifier type env) ,length ,@rest)))
      form))
