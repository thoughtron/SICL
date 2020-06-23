(cl:in-package #:asdf-user)

(defsystem #:sicl-code-generation
  :depends-on (#:sicl-mir-to-lir
               #:cluster
               #:cluster-x86-instruction-database)
  :components
  ((:file "packages")
   (:file "linearize")
   (:file "labels")
   (:file "translate-data")
   (:file "translate-instruction")
   (:file "integer-arithmetic")
   (:file "tag-test")
   (:file "memory")
   (:file "stack")
   (:file "generate-code")))
