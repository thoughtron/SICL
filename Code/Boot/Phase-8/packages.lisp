(cl:in-package #:common-lisp-user)

(defpackage #:sicl-boot-phase-8
  (:use #:common-lisp)
  (:import-from #:sicl-boot
                #:load-fasl
                #:import-function-from-host
                #:import-functions-from-host)
  (:export #:boot))
