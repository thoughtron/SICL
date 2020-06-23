(cl:in-package #:sicl-cons)

(defun getf (plist indicator &optional default)
  (unless (typep plist 'list)
    (error 'must-be-property-list
           :datum plist
           :name 'getf))
  (loop for rest on plist by #'cddr
        do (unless (consp (cdr rest))
             (error 'must-be-property-list
                    :datum plist))
        when (eq (car rest) indicator)
          return (cadr rest)
        finally (return default)))
