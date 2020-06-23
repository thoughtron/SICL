(cl:in-package #:cleavir-ir)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Data.

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Class RAW-DATUM.
;;;
;;; This class is the base class for all raw data.  It contains a size
;;; attribute that determines the number of bits that this datum
;;; consists of.

(defclass raw-datum (datum)
  ((%size :initarg :size :reader size)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Datum RAW-INTEGER.

(defclass raw-integer (raw-datum)
  ())

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Datum RAW-FLOAT.

(defclass raw-float (raw-datum)
  ())

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Instructions.

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; MIR instruction MEMREF1-INSTRUCTION
;;;
;;; This instruction loads a memory location.  It takes a single input
;;; containing the address of the word to load.  It has a single
;;; output which is set to the contents of the memory location at the
;;; address.

(defclass memref1-instruction (one-successor-mixin instruction)
  ())

(defun make-memref1-instruction (address output &optional successor)
  (make-instance 'memref1-instruction
    :inputs (list address)
    :outputs (list output)
    :successors (if (null successor) '() (list successor))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; MIR instruction MEMREF2-INSTRUCTION
;;;
;;; This instruction loads a memory location.  It takes a single input
;;; containing the address of the word to load.  It has a single
;;; output which is set to the contents of the memory location at the
;;; address specified by the input and the offset added together.

(defclass memref2-instruction (one-successor-mixin instruction)
  ((%offset :initarg :offset :reader offset)))

(defun make-memref2-instruction (base-address offset output &optional successor)
  (make-instance 'memref2-instruction
    :inputs (list base-address)
    :offset offset
    :outputs (list output)
    :successors (if (null successor) '() (list successor))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; MIR instruction MEMSET1-INSTRUCTION
;;;
;;; This instruction stores an item in a memory location.  It takes
;;; two inputs.  The first input is the address of a location in
;;; memory.  The second input is the item to be stored in that
;;; location.

(defclass memset1-instruction (one-successor-mixin instruction)
  ())

(defun make-memset1-instruction (address value &optional successor)
  (make-instance 'memset1-instruction
    :inputs (list address value)
    :outputs '()
    :successors (if (null successor) '() (list successor))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; MIR instruction MEMSET2-INSTRUCTION
;;;
;;; This instruction stores an item in a memory location.  It takes
;;; two inputs.  The first input is the address of a location in
;;; memory.  The second input is the item to be stored in that
;;; location.  This instruction adds the input address to the offset
;;; and stores the input in the resulting address.

(defclass memset2-instruction (one-successor-mixin instruction)
  ((%offset :initarg :offset :reader offset)))

(defun make-memset2-instruction (base-address offset value &optional successor)
  (make-instance 'memset2-instruction
    :inputs (list base-address value)
    :offset offset
    :outputs '()
    :successors (if (null successor) '() (list successor))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; MIR instruction SIGNED-ADD-INSTRUCTION

(defclass signed-add-instruction (multiple-successors-mixin instruction)
  ())

(defun make-signed-add-instruction
    (&key
       ((:input1 i1) nil i1-p)
       ((:input2 i2) nil i2-p)
       ((:inputs i) nil i-p)
       ((:output o) nil o-p)
       ((:successor1 s1) nil s1-p)
       ((:successor2 s2) nil s2-p)
       ((:successors s) nil s-p))
  (make-instance 'signed-add-instruction
    :inputs (construct-inputs i i-p i1 i1-p i2 i2-p)
    :outputs (construct-output o o-p)
    :successors (construct-successors s s-p s1 s1-p s2 s2-p)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; MIR instruction SIGNED-SUB-INSTRUCTION

(defclass signed-sub-instruction (multiple-successors-mixin instruction)
  ())

(defun make-signed-sub-instruction
    (&key
       ((:input1 i1) nil i1-p)
       ((:input2 i2) nil i2-p)
       ((:inputs i) nil i-p)
       ((:output o) nil o-p)
       ((:successor1 s1) nil s1-p)
       ((:successor2 s2) nil s2-p)
       ((:successors s) nil s-p))
  (make-instance 'signed-sub-instruction
    :inputs (construct-inputs i i-p i1 i1-p i2 i2-p)
    :outputs (construct-output o o-p)
    :successors (construct-successors s s-p s1 s1-p s2 s2-p)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; MIR instruction SIGNED-LESS-INSTRUCTION

(defclass signed-less-instruction (multiple-successors-mixin instruction)
  ())

(defun make-signed-less-instruction
    (&key
       ((:input1 i1) nil i1-p)
       ((:input2 i2) nil i2-p)
       ((:inputs i) nil i-p)
       ((:successor1 s1) nil s1-p)
       ((:successor2 s2) nil s2-p)
       ((:successors s) nil s-p))
  (make-instance 'signed-less-instruction
    :inputs (construct-inputs i i-p i1 i1-p i2 i2-p)
    :successors (construct-successors s s-p s1 s1-p s2 s2-p)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; MIR instruction SIGNED-NOT-GREATER-INSTRUCTION

(defclass signed-not-greater-instruction (multiple-successors-mixin instruction)
  ())

(defun make-signed-not-greater-instruction
    (&key
       ((:input1 i1) nil i1-p)
       ((:input2 i2) nil i2-p)
       ((:inputs i) nil i-p)
       ((:successor1 s1) nil s1-p)
       ((:successor2 s2) nil s2-p)
       ((:successors s) nil s-p))
  (make-instance 'signed-not-greater-instruction
    :inputs (construct-inputs i i-p i1 i1-p i2 i2-p)
    :successors (construct-successors s s-p s1 s1-p s2 s2-p)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; MIR instruction UNSIGNED-ADD-INSTRUCTION

(defclass unsigned-add-instruction (multiple-successors-mixin instruction)
  ())

(defun make-unsigned-add-instruction
    (&key
       ((:input1 i1) nil i1-p)
       ((:input2 i2) nil i2-p)
       ((:inputs i) nil i-p)
       ((:output o) nil o-p)
       ((:successor1 s1) nil s1-p)
       ((:successor2 s2) nil s2-p)
       ((:successors s) nil s-p))
  (make-instance 'unsigned-add-instruction
    :inputs (construct-inputs i i-p i1 i1-p i2 i2-p)
    :outputs (construct-output o o-p)
    :successors (construct-successors s s-p s1 s1-p s2 s2-p)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; MIR instruction UNSIGNED-SUB-INSTRUCTION

(defclass unsigned-sub-instruction (multiple-successors-mixin instruction)
  ())

(defun make-unsigned-sub-instruction
    (&key
       ((:input1 i1) nil i1-p)
       ((:input2 i2) nil i2-p)
       ((:inputs i) nil i-p)
       ((:output o) nil o-p)
       ((:successor1 s1) nil s1-p)
       ((:successor2 s2) nil s2-p)
       ((:successors s) nil s-p))
  (make-instance 'unsigned-sub-instruction
    :inputs (construct-inputs i i-p i1 i1-p i2 i2-p)
    :outputs (construct-output o o-p)
    :successors (construct-successors s s-p s1 s1-p s2 s2-p)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; MIR instruction UNSIGNED-LESS-INSTRUCTION

(defclass unsigned-less-instruction (multiple-successors-mixin instruction)
  ())

(defun make-unsigned-less-instruction
    (&key
       ((:input1 i1) nil i1-p)
       ((:input2 i2) nil i2-p)
       ((:inputs i) nil i-p)
       ((:successor1 s1) nil s1-p)
       ((:successor2 s2) nil s2-p)
       ((:successors s) nil s-p))
  (make-instance 'unsigned-less-instruction
    :inputs (construct-inputs i i-p i1 i1-p i2 i2-p)
    :successors (construct-successors s s-p s1 s1-p s2 s2-p)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; MIR instruction UNSIGNED-NOT-GREATER-INSTRUCTION

(defclass unsigned-not-greater-instruction (multiple-successors-mixin instruction)
  ())

(defun make-unsigned-not-greater-instruction
    (&key
       ((:input1 i1) nil i1-p)
       ((:input2 i2) nil i2-p)
       ((:inputs i) nil i-p)
       ((:successor1 s1) nil s1-p)
       ((:successor2 s2) nil s2-p)
       ((:successors s) nil s-p))
  (make-instance 'unsigned-not-greater-instruction
    :inputs (construct-inputs i i-p i1 i1-p i2 i2-p)
    :successors (construct-successors s s-p s1 s1-p s2 s2-p)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; MIR instruction EQUAL-INSTRUCTION

(defclass equal-instruction (multiple-successors-mixin instruction)
  ())

(defun make-equal-instruction
    (&key
       ((:input1 i1) nil i1-p)
       ((:input2 i2) nil i2-p)
       ((:inputs i) nil i-p)
       ((:successor1 s1) nil s1-p)
       ((:successor2 s2) nil s2-p)
       ((:successors s) nil s-p))
  (make-instance 'equal-instruction
    :inputs (construct-inputs i i-p i1 i1-p i2 i2-p)
    :successors (construct-successors s s-p s1 s1-p s2 s2-p)))
