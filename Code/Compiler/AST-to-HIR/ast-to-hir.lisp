(cl:in-package #:sicl-ast-to-hir)

(defun ast-to-hir (client ast)
  ;; Wrap the AST in a FUNCTION-AST that will be called at load time
  ;; with a single argument, namely a function that, given a function
  ;; name, returns the function cell from the environment the code
  ;; will be loaded into.
  (let* ((cleavir-cst-to-ast::*origin* nil)
         (hoisted-ast (cleavir-ast-transformations:hoist-load-time-value ast))
         (wrapped-ast (make-instance 'cleavir-ast:function-ast
                        :lambda-list '()
                        :body-ast hoisted-ast))
         (hir (cleavir-ast-to-hir:compile-toplevel-unhoisted client wrapped-ast)))
    (change-class hir 'sicl-hir-transformations:top-level-enter-instruction)
    (cleavir-partial-inlining:do-inlining hir)
    (sicl-argument-processing:process-parameters hir)
    (sicl-hir-transformations:preprocess-catch-instructions hir)
    (sicl-hir-transformations:preprocess-bind-instructions hir)
    (sicl-hir-transformations:preprocess-initialize-values-instructions hir)
    (sicl-hir-transformations:preprocess-multiple-value-call-instructions hir)
    (sicl-hir-transformations:preprocess-unwind-instructions hir)
    (sicl-hir-transformations:convert-symbol-value hir)
    (sicl-hir-transformations:convert-set-symbol-value hir)
    (sicl-hir-transformations:hoist-fdefinitions hir)
    (sicl-hir-transformations:eliminate-fixed-to-multiple-instructions hir)
    (sicl-hir-transformations:eliminate-multiple-to-fixed-instructions hir)
    (sicl-hir-transformations:hoist-constant-inputs hir)
    (cleavir-hir-transformations::process-captured-variables hir)
    ;; Replacing aliases does not appear to have a great effect when
    ;; code generation is disabled.  Try removing this commented line
    ;; when code generation is again enabled.
    ;; (cleavir-hir-transformations:replace-aliases hir)
    (sicl-hir-transformations:eliminate-create-cell-instructions hir)
    (sicl-hir-transformations:eliminate-fetch-instructions hir)
    (sicl-hir-transformations:eliminate-read-cell-instructions hir)
    (sicl-hir-transformations:eliminate-write-cell-instructions hir)
    (cleavir-remove-useless-instructions:remove-useless-instructions hir)
    hir))
