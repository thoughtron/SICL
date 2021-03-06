(cl:in-package #:sicl-boot-phase-8)

(defun load-hash-table-functionality (e5)
  (load-source "Hash-tables/hash-table-defclass.lisp" e5)
  (load-source "Data-and-control-flow/equalp-defgeneric.lisp" e5)
  (load-source "Hash-tables/generic-functions.lisp" e5)
  (load-source "Hash-tables/make-hash-table.lisp" e5)
  (load-source "Hash-tables/List/list-hash-table-defclass.lisp" e5)
  (load-source "Hash-tables/List/gethash-defmethod.lisp" e5)
  (load-source "Hash-tables/List/setf-gethash-defmethod.lisp" e5)
  (load-source "Hash-tables/List/remhash-defmethod.lisp" e5)
  (load-source "Hash-tables/List/clrhash-defmethod.lisp" e5)
  (load-source "Hash-tables/List/hash-table-count-defmethod.lisp" e5)
  (load-source "Hash-tables/List/maphash-defmethod.lisp" e5)
  (load-source "Hash-tables/List/make-hash-table-iterator-defmethod.lisp" e5))
