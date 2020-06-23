(cl:in-package #:sicl-hash-table)

(defclass hash-table ()
  ((%test :initarg :test
          :initform 'eql
          :reader %hash-table-test)
   (%rehash-size :initarg :rehash-size
                 :initform 1.5
                 :reader hash-table-rehash-size)
   (%rehash-threshold :initarg :rehash-threshold
                      :initform 0.8
                      :reader hash-table-rehash-threshold)))
