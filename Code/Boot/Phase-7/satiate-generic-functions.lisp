(cl:in-package #:sicl-boot-phase-7)

(defun find-all-generic-functions (e3 e5)
  (let ((result '())
        (table (make-hash-table :test #'eq)))
    (do-all-symbols (var)
      (unless (gethash var table)
        (setf (gethash var table) t)
        (when (sicl-genv:fboundp var e5)
          (let ((fun (sicl-genv:fdefinition var e5)))
            (when (and (typep fun 'sicl-boot::header)
                       (eq (slot-value fun 'sicl-boot::%class)
                           (sicl-genv:find-class 'standard-generic-function e3)))
              (push fun result))))))
    result))

(defun satiate-generic-function (function e4)
  (format *trace-output*
          "Satiating ~s~%"
          (funcall (sicl-genv:fdefinition 'sicl-clos:generic-function-name e4)
                   function))
  (funcall (sicl-genv:fdefinition 'sicl-clos::satiate-generic-function e4)
           function))

(defun satiate-generic-functions (e3 e4 e5)
  (loop for function in (find-all-generic-functions e3 e5)
        do (satiate-generic-function function e4)))
