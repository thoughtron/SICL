(cl:in-package #:sicl-sequence)

(declaim (inline map-for-effect-0))
(defun map-for-effect-0 (function)
  (loop (funcall function)))

(declaim (inline map-for-effect-1))
(defun map-for-effect-1 (function sequence)
  (if (listp sequence)
      (progn (mapc function sequence) nil)
      (let ((function (function-designator-function function)))
        (multiple-value-bind (scanner state)
            (make-sequence-scanner sequence)
          (declare (sequence-scanner scanner))
          (with-scan-buffers (scan-buffer)
            (loop
              (multiple-value-bind (amount new-state)
                  (funcall scanner sequence state scan-buffer)
                (declare (scan-amount amount))
                (setf state new-state)
                (loop for index below amount do
                  (funcall function (elt scan-buffer index)))
                (when (< amount +scan-buffer-length+)
                  (return)))))))))

(declaim (inline map-for-effect-2))
(defun map-for-effect-2 (function sequence-1 sequence-2)
  (if (and (listp sequence-1)
           (listp sequence-2))
      (progn (mapc function sequence-1 sequence-2) nil)
      (let ((function (function-designator-function function)))
        (multiple-value-bind (scanner-1 state-1)
            (make-sequence-scanner sequence-1)
          (declare (sequence-scanner scanner-1))
          (multiple-value-bind (scanner-2 state-2)
              (make-sequence-scanner sequence-2)
            (declare (sequence-scanner scanner-2))
            (with-scan-buffers (scan-buffer-1 scan-buffer-2)
              (loop
                (multiple-value-bind (amount-1 new-state-1)
                    (funcall scanner-1 sequence-1 state-1 scan-buffer-1)
                  (setf state-1 new-state-1)
                  (multiple-value-bind (amount-2 new-state-2)
                      (funcall scanner-2 sequence-2 state-2 scan-buffer-2)
                    (setf state-2 new-state-2)
                    (let ((amount (min amount-1 amount-2)))
                      (loop for index below amount do
                        (funcall function
                                 (elt scan-buffer-1 index)
                                 (elt scan-buffer-2 index)))
                      (when (< amount +scan-buffer-length+)
                        (return))))))))))))

(declaim (inline map-for-effect-3))
(defun map-for-effect-3 (function sequence-1 sequence-2 sequence-3)
  (if (and (listp sequence-1)
           (listp sequence-2)
           (listp sequence-3))
      (progn (mapc function sequence-1 sequence-2 sequence-3) nil)
      (let ((function (function-designator-function function)))
        (multiple-value-bind (scanner-1 state-1)
            (make-sequence-scanner sequence-1)
          (declare (sequence-scanner scanner-1))
          (multiple-value-bind (scanner-2 state-2)
              (make-sequence-scanner sequence-2)
            (declare (sequence-scanner scanner-2))
            (multiple-value-bind (scanner-3 state-3)
                (make-sequence-scanner sequence-3)
              (declare (sequence-scanner scanner-3))
              (with-scan-buffers (scan-buffer-1 scan-buffer-2 scan-buffer-3)
                (loop
                  (multiple-value-bind (amount-1 new-state-1)
                      (funcall scanner-1 sequence-1 state-1 scan-buffer-1)
                    (setf state-1 new-state-1)
                    (multiple-value-bind (amount-2 new-state-2)
                        (funcall scanner-2 sequence-2 state-2 scan-buffer-2)
                      (setf state-2 new-state-2)
                      (multiple-value-bind (amount-3 new-state-3)
                          (funcall scanner-3 sequence-3 state-3 scan-buffer-3)
                        (setf state-3 new-state-3)
                        (let ((amount (min amount-1 amount-2 amount-3)))
                          (loop for index below amount do
                            (funcall function
                                     (elt scan-buffer-1 index)
                                     (elt scan-buffer-2 index)
                                     (elt scan-buffer-3 index)))
                          (when (< amount +scan-buffer-length+)
                            (return))))))))))))))

(defun map-for-effect-n (function &rest sequences)
  (if (every #'listp sequences)
      (progn (apply #'mapc function sequences) nil)
      (let* ((function (function-designator-function function))
             (n-sequences (cl:length sequences))
             (scanners (make-array n-sequences))
             (states (make-array n-sequences))
             (scan-buffers (make-array n-sequences)))
        (declare (optimize speed))
        (loop for sequence in sequences
              for index from 0 do
                (setf (values
                       (svref scanners index)
                       (svref states index))
                      (make-sequence-scanner sequence))
                (setf (svref scan-buffers index)
                      (make-scan-buffer)))
        (loop
          (let ((amount +scan-buffer-length+))
            (declare (scan-amount amount))
            ;; Fill all scan buffers and minimize the amount.
            (loop for sequence in sequences
                  and index below n-sequences
                  do (symbol-macrolet
                         ((scanner (the sequence-scanner (svref scanners index)))
                          (state (svref states index))
                          (scan-buffer (the scan-buffer (svref scan-buffers index))))
                       (multiple-value-bind (amount-n new-state)
                           (funcall scanner sequence state scan-buffer)
                         (when (< amount-n amount)
                           (setf amount amount-n))
                         (setf state new-state))))
            (loop for index below amount do
              (let ((args '()))
                (loop for pos from (1- n-sequences) downto 0 do
                  (push (svref (svref scan-buffers pos) index) args))
                (apply function args))
              (when (< amount +scan-buffer-length+)
                (return))))))))

(defun map-for-effect (function &rest sequences)
  (case (length sequences)
    (0 (map-for-effect-0 function))
    (1 (map-for-effect-1 function (first sequences)))
    (2 (map-for-effect-2 function (first sequences) (second sequences)))
    (3 (map-for-effect-3 function (first sequences) (second sequences) (third sequences)))
    (otherwise
     (apply #'map-for-effect-n function sequences))))

(define-compiler-macro map-for-effect (function &rest sequences)
  (case (length sequences)
    (0 `(map-for-effect-0 ,function))
    (1 `(map-for-effect-1 ,function ,@sequences))
    (2 `(map-for-effect-2 ,function ,@sequences))
    (3 `(map-for-effect-3 ,function ,@sequences))
    (otherwise
     `(map-for-effect-n ,function ,@sequences))))
