(cl:in-package #:common-lisp-user)

(defpackage #:sicl-bucket-hash-table
  (:import-from #:sicl-hash-table
                #:find-hash-function
                #:with-hash-table-iterator
                #:%hash-table-test)
  (:use #:common-lisp)
  (:export #:bucket-hash-table))
