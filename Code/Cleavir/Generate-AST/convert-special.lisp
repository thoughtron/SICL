(in-package #:cleavir-generate-ast)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Converting QUOTE.

(defmethod convert-special
    ((symbol (eql 'quote)) form env system)
  (db s (quote const) form
    (declare (ignore quote))
    (convert-constant const env system)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Converting BLOCK.

(defmethod convert-special
    ((symbol (eql 'block)) form env system)
  (db origin (block name . body) form
    (declare (ignore block))
    (let* ((ast (cleavir-ast:make-block-ast nil :origin origin))
	   (new-env (cleavir-env:add-block env name ast)))
      (setf (cleavir-ast:body-ast ast)
	    (process-progn (convert-sequence body new-env system)))
      ast)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Converting EVAL-WHEN.

(defmethod convert-special
    ((symbol (eql 'eval-when)) form environment system)
  (with-preserved-toplevel-ness
    (db s (eval-when situations . body) form
      (declare (ignore eval-when))
      (if (or (eq *compiler* 'cl:compile)
	      (eq *compiler* 'cl:eval)
	      (not *current-form-is-top-level-p*))
	  (if (or (member :execute situations)
		  (member 'eval situations))
	      (process-progn
	       (convert-sequence body environment system))
	      (convert nil environment system))
	  (cond ((or
		  ;; CT   LT   E    Mode
		  ;; Yes  Yes  ---  ---
		  (and (or (member :compile-toplevel situations)
			   (member 'compile situations))
		       (or (member :load-toplevel situations)
			   (member 'load situations)))
		  ;; CT   LT   E    Mode
		  ;; No   Yes  Yes  CTT
		  (and (not (or (member :compile-toplevel situations)
				(member 'compile situations)))
		       (or (member :load-toplevel situations)
			   (member 'load situations))
		       (or (member :execute situations)
			   (member 'eval situations))
		       *compile-time-too*))
		 (let ((*compile-time-too* t))
		   (convert `(progn ,@body) environment system)))
		((or
		  ;; CT   LT   E    Mode
		  ;; No   Yes  Yes  NCT
		  (and (not (or (member :compile-toplevel situations)
				(member 'compile situations)))
		       (or (member :load-toplevel situations)
			   (member 'load situations))
		       (or (member :execute situations)
			   (member 'eval situations))
		       (not *compile-time-too*))
		  ;; CT   LT   E    Mode
		  ;; No   Yes  No   ---
		  (and (not (or (member :compile-toplevel situations)
				(member 'compile situations)))
		       (or (member :load-toplevel situations)
			   (member 'load situations))
		       (not (or (member :execute situations)
				(member 'eval situations)))))
		 (let ((*compile-time-too* nil))
		   (convert `(progn ,@body) environment system)))
		((or
		  ;; CT   LT   E    Mode
		  ;; Yes  No   ---  ---
		  (and (or (member :compile-toplevel situations)
			   (member 'compile situations))
		       (not (or (member :load-toplevel situations)
				(member 'load situations))))
		  ;; CT   LT   E    Mode
		  ;; No   No   Yes  CTT
		  (and (not (or (member :compile-toplevel situations)
				(member 'compile situations)))
		       (not (or (member :load-toplevel situations)
				(member 'load situations)))
		       (or (member :execute situations)
			   (member 'eval situations))
		       *compile-time-too*))
		 (cleavir-env:eval `(progn ,@body) environment environment)
		 (convert nil environment system))
		(t
		 (convert nil environment system)))))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Converting FLET.

;;; Take an environment and a single function definition, and return a
;;; new environment which is like the one passed as an argument except
;;; that it has been augmented by the local function name.
(defun augment-environment-from-fdef (environment definition)
  (db origin (name . rest) definition
    (declare (ignore rest))
    (let ((var-ast (cleavir-ast:make-lexical-ast (raw name)
						 :origin origin)))
      (cleavir-env:add-local-function environment name var-ast))))

;;; Take an environment, a list of function definitions, and bound
;;; decls, and return a new environment which is like the one passed
;;; as an argument, except that is has been augmented by the
;;; local function names in the list.
(defun augment-environment-from-fdefs (environment definitions)
  (loop with result = environment
	for definition in (raw definitions)
	do (setf result
		 (augment-environment-from-fdef result definition))
	finally (return result)))

;;; Given an environment and the name of a function, return the
;;; LEXICAL-AST that will have the function with that name as a value.
;;; It is known that the environment contains an entry corresponding
;;; to the name given as an argument.
(defun function-lexical (environment name)
  (cleavir-env:identity (cleavir-env:function-info environment name)))

;;; Given a function name, determine the name of a block that should
;;; be associated with the function with that name.
(defun block-name-from-function-name (function-name)
  (if (symbolp function-name)
      function-name
      (second function-name)))

;;; Convert a local function definition.
(defun convert-local-function (definition environment system)
  (db s (name lambda-list . body) definition
    (let ((block-name (block-name-from-function-name name)))
      (convert-code lambda-list body environment system :block-name block-name))))

;;; Compute and return a list of SETQ-ASTs that will assign the
;;; definition of each function in a list of function definitions to
;;; its associated LEXICAL-AST.
(defun compute-function-init-asts (definitions env)
  (loop for (name . fun-ast) in definitions
	collect (cleavir-ast:make-setq-ast
		 (function-lexical env name)
		 fun-ast)))

;;; Given a list of declarations, i.e., a list of the form:
;;;
;;; ((DECLARE <declaration-specifier> ... <declaration-specifier>)
;;;  (DECLARE <declaration-specifier> ... <declaration-specifier>)
;;;  ...
;;;  (DECLARE <declaration-specifier> ... <declaration-specifier>))
;;;
;;; Return a list of all the declaration specifiers.
(defun declaration-specifiers (declarations)
  (reduce #'append (mapcar #'cdr declarations)
	  :from-end t))

;;; Given a list of declarations, return a list of canonicalized
;;; declaration specifiers of all the declarations.
(defun canonicalize-declarations (declarations env)
  (cleavir-code-utilities:canonicalize-declaration-specifiers
   (declaration-specifiers declarations)
   (cleavir-env:declarations env)))

;;; Search for (dynamic-extent #'name).
(defun dx-function-in-decls-p (canonicalized-dspecs name)
  (loop for spec in canonicalized-dspecs
        when (and (eq (first spec) 'dynamic-extent)
                  (equal (second spec) `#',name))
          do (return t)
        finally (return nil)))

(defmethod convert-special ((symbol (eql 'flet)) form env system)
  (db s (flet definitions . body) form
    (declare (ignore flet))
    (multiple-value-bind (declarations forms)
	(cleavir-code-utilities:separate-ordinary-body body)
      (let* ((canonicalized-dspecs
               (canonicalize-declarations declarations env))
             (defs (loop for def in (raw definitions)
                         for name = (first def)
                         for fun = (convert-local-function
                                    def env system)
                         ;; collect DX info
                         when (dx-function-in-decls-p canonicalized-dspecs
                                                      name)
                           collect (cons name
                                         (cleavir-ast:make-dynamic-allocation-ast
                                          fun))
                         else collect (cons name fun)))
	     (new-env (augment-environment-from-fdefs env defs))
	     (init-asts
	       (compute-function-init-asts defs new-env))
	     (new-env (augment-environment-with-declarations
		       new-env canonicalized-dspecs)))
	(process-progn
	 (append init-asts
		 ;; so that flet with empty body works.
		 (list
		  (process-progn
		   (convert-sequence forms new-env system)))))))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Converting FUNCTION.

(defgeneric convert-global-function (info global-env system))

(defmethod convert-global-function (info global-env system)
  (declare (ignore global-env))
  (cleavir-ast:make-fdefinition-ast
   (cleavir-ast:make-load-time-value-ast `',(cleavir-env:name info) t)))

(defmethod convert-function
    ((info cleavir-env:global-function-info) env system)
  (convert-global-function info (cleavir-env:global-environment env) system))

(defmethod convert-function
    ((info cleavir-env:local-function-info) env system)
  (declare (ignore env system))
  (cleavir-env:identity info))

(defmethod convert-function
    ((info cleavir-env:global-macro-info) env system)
  (error 'function-name-names-global-macro
	 :expr (cleavir-env:name info)))

(defmethod convert-function
    ((info cleavir-env:local-macro-info) env system)
  (error 'function-name-names-local-macro
	 :expr (cleavir-env:name info)))

(defmethod convert-function
    ((info cleavir-env:special-operator-info) env system)
  (error 'function-name-names-special-operator
	 :expr (cleavir-env:name info)))

(defun convert-named-function (name environment system)
  (let ((info (function-info environment name)))
    (convert-function info environment system)))

(defun convert-lambda-function (lambda-form env system)
  (convert-code (cadr lambda-form) (cddr lambda-form) env system))

(defmethod convert-special ((symbol (eql 'function)) form env system)
  (db s (function name) form
    (declare (ignore function))
    (if (proper-function-name-p name)
	(convert-named-function name env system)
	(convert-lambda-function name env system))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Converting GO.

(defmethod convert-special ((symbol (eql 'go)) form env system)
  (declare (ignore system))
  (db origin (go tag) form
    (declare (ignore go))
    (let ((info (tag-info env (raw tag))))
      (cleavir-ast:make-go-ast (cleavir-env:identity info)
                               :origin origin))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Converting IF.

(defmethod convert-special ((symbol (eql 'if)) form env system)
  (db origin (if test then . tail) form
    (declare (ignore if))
    (let ((test-ast (convert test env system))
	  (true-ast (convert then env system))
	  (false-ast (if (null tail)
			 (convert-constant nil env system)
			 (db s (else) tail
			   (convert else env system)))))
      (if (typep test-ast 'cleavir-ast:boolean-ast-mixin)
	  (cleavir-ast:make-if-ast
	   test-ast
	   true-ast
	   false-ast
	   :origin origin)
	  (cleavir-ast:make-if-ast
	   (cleavir-ast:make-eq-ast test-ast (convert-constant nil env system))
	   false-ast
	   true-ast
	   :origin origin)))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Converting LABELS.

;;; Given a list of local function definitions, return a list of
;;; the names of those functions.
(defun function-names (definitions)
  (mapcar #'car definitions))

;;; "for labels, any inline, notinline, or ftype declarations that
;;;  refer to the locally defined functions do apply to the local
;;;  function bodies"
(defun labels-dspecs (dspecs defs)
  "Given a list of canoncalized dspecs from the body of a LABELS form, and the labels definitions, picks out those declarations that apply to the function bodies, i.e. ftype, inline, and notinline on the names."
  (loop with names = (function-names defs)
	for dspec in dspecs
	when (eq (first dspec) 'ftype)
	  when (find (third dspec) names)
	    collect dspec
	when (find (first dspec) '(inline notinline))
	  when (find (second dspec) names)
	    collect dspec))

(defmethod convert-special ((symbol (eql 'labels)) form env system)
  (db s (labels definitions . body) form
    (declare (ignore labels))
    (multiple-value-bind (declarations forms)
	(cleavir-code-utilities:separate-ordinary-body body)
      ;; basically, makes a new env with the function names
      ;;  and selected declarations (labels-dspecs) and converts
      ;;  the function bodies there. then, makes a new child of
      ;;  that with the inline expansions and all declarations.
      ;; FIXME?: right now the local bodies cannot inline each
      ;;  other at all (as is allowed, but not required). A more
      ;;  sophisticated thing would be to check which have INLINE
      ;;  declarations, convert those bodies, and have those
      ;;  expansions available while converting the others.
      ;; Even more sophisticated would be making a graph of what
      ;;  can inline what and converting in several stages, but
      ;;  that's probably too clever by half.
      (let* ((canonicalized-dspecs
	       (canonicalize-declarations declarations env))
	     (outer-env
	       (augment-environment-from-fdefs env definitions))
	     (body-dspecs
	       (labels-dspecs canonicalized-dspecs
			      (raw definitions)))
	     (outer-env (augment-environment-with-declarations
			 outer-env body-dspecs))
	     (defs (loop for def in (raw definitions)
                         for name = (first def)
                         for fun = (convert-local-function
                                    def outer-env system)
                         when (dx-function-in-decls-p
                               canonicalized-dspecs name)
                           collect (cons name
                                         (cleavir-ast:make-dynamic-allocation-ast
                                          fun))
                         else collect (cons name fun)))
	     (init-asts
	       (compute-function-init-asts defs outer-env))
	     (inner-env (augment-environment-with-declarations
			 outer-env canonicalized-dspecs)))
	(process-progn
	 (append
	  init-asts
	  (list
	   (process-progn
	    (convert-sequence forms inner-env system)))))))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Converting LET and LET*

(defun binding-init-form (binding)
  (if (or (symbolp binding) (null (cdr binding)))
      nil
      (cadr binding)))

(defun binding-init-forms (bindings)
  (mapcar #'binding-init-form bindings))

(defun binding-var (binding)
  (if (symbolp binding)
      binding
      (first binding)))

(defun binding-vars (bindings)
  (mapcar #'binding-var bindings))

;;; For converting LET, we use a method that is very close to the
;;; exact wording of the Common Lisp HyperSpec, in that we first
;;; evaluate the INIT-FORMs in the original environment and save the
;;; resulting values.  We save those resulting values in
;;; freshly-created lexical variables.  Then we bind each original
;;; variable, either by using a SETQ-AST or a BIND-AST according to
;;; whether the variable to be bound is lexical or special.

;;; BINDINGS is a list of CONS cells.  The CAR of each CONS cell is a
;;; variable to be bound.  The CDR of each CONS cell is a LEXICAL-AST
;;; that corresponds to a lexical variable holding the result of the
;;; computation of the initial value for that variable.  IDSPECS is a
;;; list with the same length as BINDINGS of itemized canonicalized
;;; declaration specifiers.  Each item in the list is a list of
;;; canonicalized declaration specifiers associated with the
;;; corresponding variable in the BINDINGS list.  RDSPECS is a list of
;;; remaining canonicalized declaration specifiers that apply to the
;;; environment in which the FORMS are to be processed.
(defun process-remaining-let-bindings (bindings idspecs rdspecs forms env system)
  (if (null bindings)
      ;; We ran out of bindings.  We must build an AST for the body of
      ;; the function.
      (let ((new-env (augment-environment-with-declarations env rdspecs)))
	(process-progn (convert-sequence forms new-env system)))
      (destructuring-bind (var . lexical-ast) (first bindings)
	(let (;; We enter the new variable into the environment and
              ;; then we process remaining parameters and ultimately
              ;; the body of the function.
              (new-env (augment-environment-with-variable
                        var (first idspecs) env env)))
          (set-or-bind-variable var lexical-ast
                                (lambda ()
                                  (process-remaining-let-bindings
                                   (rest bindings) (rest idspecs)
                                   rdspecs forms new-env system))
                                new-env system)))))

(defun temp-asts-from-bindings (bindings)
  (loop repeat (length bindings)
	collect (cleavir-ast:make-lexical-ast (gensym))))

;;; Given a list of items, return which is like the one given as
;;; argument, except that each item has been wrapped in a (singleton)
;;; list.
(defun listify (items)
  (mapcar #'list items))

;;; Given two lists of equal length, pair the items so that the items
;;; in LIST1 are stored in the CAR of the resulting CONS cells, and
;;; the items in LIST2 are stored in the CDR of the resulting CONS
;;; cells.  The order is preserved from the original lists.
(defun pair-items (list1 list2)
  (mapcar #'cons list1 list2))

(defun make-let-init-asts (bindings temp-asts idspecs env system)
  (loop for init-form in (binding-init-forms bindings)
        for idspec in idspecs
	for converted = (convert init-form env system)
        for wrapped = (if (member 'dynamic-extent idspec :key #'car)
                          (cleavir-ast:make-dynamic-allocation-ast
                           converted)
                          converted)
	for temp-ast in temp-asts
	collect (cleavir-ast:make-setq-ast temp-ast wrapped)))

(defmethod convert-special
    ((symbol (eql 'let)) form env system)
  (db s (let bindings . body) form
    (declare (ignore let))
    (multiple-value-bind (declarations forms)
	(cleavir-code-utilities:separate-ordinary-body body)
      (let* ((canonical-dspecs
               (canonicalize-declarations declarations env))
	     (variables (binding-vars bindings))
	     (temp-asts (temp-asts-from-bindings (raw bindings))))
	(multiple-value-bind (idspecs rdspecs)
            (itemize-declaration-specifiers (listify variables)
                                            canonical-dspecs)
	  (process-progn
	   (append (make-let-init-asts bindings temp-asts
                                       idspecs
                                       env system)
		   (list (process-remaining-let-bindings
			  (pair-items variables temp-asts)
			  idspecs
			  rdspecs
			  forms
			  env
			  system)))))))))

;;; BINDINGS is a list of CONS cells.  The CAR of each CONS cell is a
;;; variable to be bound.  The CDR of each CONS cell is an init-form
;;; computing the initial value for that variable.  IDSPECS is a list
;;; with the same length as BINDINGS of itemized canonicalized
;;; declaration specifiers.  Each item in the list is a list of
;;; canonicalized declaration specifiers associated with the
;;; corresponding variable in the BINDINGS list.  RDSPECS is a list of
;;; remaining canonicalized declaration specifiers that apply to the
;;; environment in which the FORMS are to be processed.
(defun process-remaining-let*-bindings
    (bindings idspecs rdspecs forms env system)
  (if (null bindings)
      ;; We ran out of bindings.  We must build an AST for the body of
      ;; the function.
      (let ((new-env (augment-environment-with-declarations env rdspecs)))
	(process-progn (convert-sequence forms new-env system)))
      (destructuring-bind (var . init-form) (first bindings)
	(let* (;; We enter the new variable into the environment and
	       ;; then we process remaining parameters and ultimately
	       ;; the body of the function.
	       (new-env (augment-environment-with-variable
			 var (first idspecs) env env))
	       ;; The initform of the &AUX parameter is turned into an
	       ;; AST in the original environment, i.e. the one that
	       ;; does not have the parameter variable in it.
	       (value-ast (convert init-form env system))
               ;; Maybe wrap the value in a dynamic-allocation.
               (wrapped-ast (if (find 'dynamic-extent (first idspecs)
                                      :key #'car :test #'eq)
                                (cleavir-ast:make-dynamic-allocation-ast
                                 value-ast)
                                value-ast)))
          (set-or-bind-variable
           var wrapped-ast
           (lambda ()
             ;; We compute the AST of the remaining computation by
             ;; recursively calling this same function with the
             ;; remaining bindings (if any) and the environment that
	       ;; we obtained by augmenting the original one with the
             ;; parameter variable.
             (process-remaining-let*-bindings (rest bindings)
                                              (rest idspecs)
                                              rdspecs
                                              forms
                                              new-env
                                              system))
           new-env system)))))

(defmethod convert-special
    ((symbol (eql 'let*)) form env system)
  (db s (let* bindings . body) form
    (declare (ignore let*))
    (multiple-value-bind (declarations forms)
	(cleavir-code-utilities:separate-ordinary-body body)
      (let* ((canonical-dspecs
               (canonicalize-declarations declarations env))
	     (variables (binding-vars bindings))
	     (init-forms (binding-init-forms bindings)))
	(multiple-value-bind (idspecs rdspecs) (itemize-declaration-specifiers
						(listify variables)
						canonical-dspecs)
	  (process-remaining-let*-bindings (pair-items variables init-forms)
					   idspecs
					   rdspecs
					   forms
					   env
					   system))))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Converting LOAD-TIME-VALUE.

(defmethod convert-special
    ((symbol (eql 'load-time-value)) form environment system)
  (declare (ignore system))
  (db s (load-time-value form . remaining) form
    (declare (ignore load-time-value))
    (cleavir-ast:make-load-time-value-ast
     form
     (if (null remaining)
	 nil
	 (db s (read-only-p) remaining
	   (raw read-only-p))))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Converting LOCALLY.
;;;
;;; According to section 3.2.3.1 of the HyperSpec, LOCALLY processes
;;; its subforms the same way as the form itself.

(defmethod convert-special
    ((symbol (eql 'locally)) form env system)
  (db s (locally . body) form
    (declare (ignore locally))
    (multiple-value-bind (declarations forms)
	(cleavir-code-utilities:separate-ordinary-body body)
      (let ((canonicalized-dspecs
              (canonicalize-declarations declarations env)))
	(let ((new-env (augment-environment-with-declarations
			env canonicalized-dspecs)))
	  (with-preserved-toplevel-ness
	    (process-progn
	     (convert-sequence forms new-env system))))))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Converting MACROLET.
;;;
;;; According to section 3.2.3.1 of the HyperSpec, MACROLET processes
;;; its subforms the same way as the form itself.

;;; Given a MACROLET definition and an environment, return a macro
;;; expander (or macro function) for the definition.
(defun expander (definition environment)
  (destructuring-bind (name lambda-list . body) definition
    (let ((lambda-expression
	    (cleavir-code-utilities:parse-macro name
						lambda-list
						body
						environment)))
      (cleavir-env:eval lambda-expression
                        (cleavir-env:compile-time environment)
                        environment))))

(defmethod convert-special
    ((symbol (eql 'macrolet)) form env system)
  (destructuring-bind (definitions &rest body) (rest form)
    (let ((new-env env))
      (loop for definition in definitions
	    for name = (first definition)
	    for expander = (expander definition env)
	    do (setf new-env
		     (cleavir-env:add-local-macro new-env name expander)))
      (with-preserved-toplevel-ness
	(convert `(locally ,@body) new-env system)))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Converting PROGN.
;;;
;;; According to section 3.2.3.1 of the HyperSpec, PROGN processes
;;; its subforms the same way as the form itself.

(defmethod convert-special
    ((head (eql 'progn)) form environment system)
  (with-preserved-toplevel-ness
    (db s (progn . forms) form
      (declare (ignore progn))
      (process-progn
       (convert-sequence forms environment system)))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Converting RETURN-FROM.

(defmethod convert-special
    ((symbol (eql 'return-from)) form env system)
  (db origin (return-from block-name . rest) form
    (declare (ignore return-from))
    (let ((info (block-info env block-name))
	  (value-form (if (null rest) nil (first rest))))
      (cleavir-ast:make-return-from-ast
       (cleavir-env:identity info)
       (convert value-form env system)
       :origin origin))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Converting SETQ.
;;;
;;; Recall that the SETQ-AST is a NO-VALUE-AST-MIXIN.  We must
;;; therefore make sure it is always compiled in a context where its
;;; value is not needed.  We do that by wrapping a PROGN around it.

(defgeneric convert-setq (info var form env system))

(defmethod convert-setq
    ((info cleavir-env:constant-variable-info) var form env system)
  (declare (ignore var))
  (declare (ignore env system form))
  (error 'setq-constant-variable
	 :expr (cleavir-env:name info)))

(defmethod convert-setq
    ((info cleavir-env:lexical-variable-info) var form env system)
  (process-progn 
   (list (cleavir-ast:make-setq-ast
	  (cleavir-env:identity info)
	  (convert form env system)
	  :origin (location var))
	 (cleavir-env:identity info))))

(defmethod convert-setq
    ((info cleavir-env:symbol-macro-info) var form env system)
  (declare (ignore var))
  (let ((expansion (funcall (coerce *macroexpand-hook* 'function)
			    (lambda (form env)
			      (declare (ignore form env))
			      (cleavir-env:expansion info))
			    (cleavir-env:name info)
			    env)))
    (convert `(setf ,expansion ,form) env system)))

(defgeneric convert-setq-special-variable
    (info var form-ast global-env system))

(defmethod convert-setq-special-variable
    (info var form-ast global-env system)
  (declare (ignore system))
  (let ((temp (cleavir-ast:make-lexical-ast (gensym))))
    (process-progn
     (list (cleavir-ast:make-setq-ast temp form-ast)
	   (cleavir-ast:make-set-symbol-value-ast
	    (cleavir-ast:make-load-time-value-ast `',(cleavir-env:name info))
	    temp
	    :origin (location var))
	   temp))))

(defmethod convert-setq
    ((info cleavir-env:special-variable-info) var form env system)
  (let ((global-env (cleavir-env:global-environment env)))
    (convert-setq-special-variable info
				   var
				   (convert form env system)
				   global-env
				   system)))

(defun convert-elementary-setq (var form env system)
  (convert-setq (variable-info env (raw var))
		var
		form
		env
		system))
  
(defmethod convert-special
    ((symbol (eql 'setq)) form environment system)
  (let ((form-asts (loop for (var form) on (cdr (raw form)) by #'cddr
			 collect (convert-elementary-setq
				  var form environment system))))
    (process-progn form-asts)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Converting SYMBOL-MACROLET.

(defmethod convert-special
    ((head (eql 'symbol-macrolet)) form env system)
  (let ((new-env env))
    (loop for (name expansion) in (cadr form)
	  do (setf new-env
		   (cleavir-env:add-local-symbol-macro new-env name expansion)))
    (with-preserved-toplevel-ness
      (convert `(locally ,@(cddr form)) new-env system))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Converting TAGBODY.
;;;
;;; The TAGBODY special form always returns NIL.  We generate a PROGN
;;; with the TAGBODY-AST and a CONSTANT-AST in it, because the
;;; TAGBODY-AST (unlike hte TAGBODY special form) does not generate a
;;; value.

(defun tagp (item)
  ;; go tags are symbols or integers, per CLHS glossary.
  (or (symbolp item)
      (integerp item)))

(defmethod convert-special
    ((symbol (eql 'tagbody)) form env system)
  (db origin (tagbody . items) form
    (declare (ignore tagbody))
    (let ((tag-asts
            (loop for item in (raw items)
                  for raw-item = (raw item)
                  when (tagp raw-item)
                    collect (cleavir-ast:make-tag-ast
                             raw-item
                             :origin (location item))))
          (new-env env))
      (loop for ast in tag-asts
	    do (setf new-env (cleavir-env:add-tag
			      new-env (cleavir-ast:name ast) ast)))
      (let ((item-asts (loop for item in (raw items)
			     collect (if (tagp (raw item))
					 (pop tag-asts)
					 (convert item new-env system)))))
	(process-progn
	 (list (cleavir-ast:make-tagbody-ast item-asts :origin origin)
	       (convert-constant nil env system)))))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Converting THE.

(defmethod convert-special
    ((symbol (eql 'the)) form environment system)
  (db origin (the value-type subform) form
    (declare (ignore the))
    (multiple-value-bind (req opt rest)
	(the-values-components value-type)
      ;; we don't bother collapsing THE forms for user code.
      (cleavir-ast:make-the-ast
       (convert subform environment system)
       req opt rest
       :origin origin))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Converting MULTIPLE-VALUE-PROG1.

(defmethod convert-special
    ((symbol (eql 'multiple-value-prog1)) form environment system)
  (db s (multiple-value-prog1 first-form . forms) form
    (declare (ignore multiple-value-prog1))
    (cleavir-ast:make-multiple-value-prog1-ast
     (convert first-form environment system)
     (convert-sequence forms environment system)
     :origin (location form))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Methods specialized to operators for which we do not provide a
;;; conversion method.

;;; Implementations should probably convert this in terms of
;;; CLEAVIR-PRIMOP:MULTIPLE-VALUE-CALL.
(defmethod convert-special
    ((symbol (eql 'multiple-value-call)) form environment system)
  (declare (ignore environment system))
  (error 'no-default-method :operator symbol :expr form))

(defmethod convert-special
    ((symbol (eql 'unwind-protect)) form environment system)
  (declare (ignore environment system))
  (error 'no-default-method :operator symbol :expr form))

(defmethod convert-special
    ((symbol (eql 'catch)) form environment system)
  (declare (ignore environment system))
  (error 'no-default-method :operator symbol :expr form))

(defmethod convert-special
    ((symbol (eql 'throw)) form environment system)
  (declare (ignore environment system))
  (error 'no-default-method :operator symbol :expr form))

(defmethod convert-special
    ((symbol (eql 'progv)) form environment system)
  (declare (ignore environment system))
  (error 'no-default-method :operator symbol :expr form))
