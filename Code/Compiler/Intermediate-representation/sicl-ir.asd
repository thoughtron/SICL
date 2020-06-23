(cl:in-package #:asdf-user)

(defsystem #:sicl-ir
  :depends-on (:cleavir2-ir)
  :serial t
  :components
  ((:file "packages")
   (:file "breakpoint-instruction")
   (:file "dynamic-environment")
   (:file "stack")))

   
