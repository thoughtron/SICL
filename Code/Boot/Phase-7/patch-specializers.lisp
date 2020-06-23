(cl:in-package #:sicl-boot-phase-7)

(defun gf-methods (gf e5)
  (funcall (sicl-genv:fdefinition 'sicl-clos:generic-function-methods e5)
           gf))

(defun find-replacement-class (class e5)
  (let* ((name (funcall (sicl-genv:fdefinition 'sicl-clos:class-name e5) class))
         (replacement (sicl-genv:find-class name e5)))
    (assert (not (null replacement)))
    replacement))

(defun patch-specializers (method e5)
  (let ((specializers 
          (funcall (sicl-genv:fdefinition 'sicl-clos:method-specializers e5)
                   method)))
    (loop for rest = specializers then (rest rest)
          until (null rest)
          do (format *trace-output*
                     "Replacing ~s by ~s~%"
                     (first rest)
                     (find-replacement-class (first rest) e5))
             (setf (first rest)
                   (find-replacement-class (first rest) e5)))))

(defun patch-method-specializers (e5)
  (let ((table (make-hash-table :test #'equal)))
    (do-all-symbols (symbol)
      (unless (gethash symbol table)
        (setf (gethash symbol table) t)
        (when (sicl-genv:fboundp symbol e5)
          (let ((definition (sicl-genv:fdefinition symbol e5)))
            (when (and (typep definition 'sicl-boot::header)
                       (eq (slot-value definition 'sicl-boot::%class)
                           (sicl-genv:find-class 'standard-generic-function e5)))
              (format *trace-output* "patching ~s~%" symbol)
              (let* ((methods (gf-methods definition e5)))
                (mapc (lambda (m) (patch-specializers m e5))
                      methods)))))))))
