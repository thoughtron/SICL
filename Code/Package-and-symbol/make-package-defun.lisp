(cl:in-package #:sicl-package)

;;; FIXME: signal correctable errors.
;;; FIXME: check that nicknames is a proper list of string designators
;;; FIXME: check that use is a proper list of package designators.
(defun make-package (name &key nicknames use)
  (let* ((name-string (string name))
         (nickname-strings (mapcar #'string nicknames))
         (all-name-strings (cons name-string nickname-strings))
         (environment (sicl-genv:global-environment))
         (existing-packages
           (loop for name in all-name-strings
                 for package = (sicl-genv:find-package name environment)
                 unless (null package)
                   collect package)))
    (loop until (null existing-packages)
          do (restart-case (error 'package-already-exists
                                  :packages existing-packages)
               (force (stuff)
                 :report (lambda (stream)
                           (format stream
                                   "Replace the existing packages."))
                 (mapc #'delete-package existing-packages)
                 (setf existing-packages '()))))
    (let ((package (make-instance 'package
                     :name name-string
                     :nicknames nickname-strings
                     ;; FIXME: create with a use list of '() and then
                     ;; import and check for errors.
                     :use-list use)))
      (loop for name in all-name-strings
            do (setf (sicl-genv:find-package name environment)
                     package))
      package)))
