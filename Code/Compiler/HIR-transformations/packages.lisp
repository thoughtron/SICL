(cl:in-package #:common-lisp-user)

(defpackage sicl-hir-transformations
  (:use #:common-lisp)
  (:export #:hoist-fdefinitions
           #:name
           #:convert-symbol-value
           #:convert-set-symbol-value
           #:eliminate-create-cell-instructions
           #:eliminate-fetch-instructions
           #:eliminate-read-cell-instructions
           #:eliminate-write-cell-instructions
           #:constants
           #:function-names
           #:top-level-enter-instruction
           #:hoist-constant-inputs
           #:eliminate-fixed-to-multiple-instructions
           #:eliminate-multiple-to-fixed-instructions
           #:preprocess-unwind-instructions
           #:preprocess-catch-instructions
           #:preprocess-bind-instructions
           #:preprocess-initialize-values-instructions
           #:preprocess-multiple-value-call-instructions
           #:preprocess-unwind-instructions
           #:eliminate-append-values-instructions))
