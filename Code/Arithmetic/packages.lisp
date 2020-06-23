(cl:in-package #:common-lisp-user)

(defpackage #:sicl-arithmetic
  (:use #:common-lisp)
  (:export
   #:binary-add
   #:binary-subtract
   #:binary-multiply
   #:binary-divide
   #:binary-less
   #:binary-not-greater
   #:binary-greater
   #:binary-not-less
   #:binary-equal
   #:sign-and-limb-count))
