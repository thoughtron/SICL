(cl:in-package #:cleavir-ir)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Instruction FIXNUM-ADD-INSTRUCTION.

(defclass fixnum-add-instruction (multiple-successors-mixin instruction)
  ())

(defun make-fixnum-add-instruction (inputs output successors)
  (make-instance 'fixnum-add-instruction
    :inputs inputs
    :outputs (list output)
    :successors successors))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Instruction FIXNUM-SUB-INSTRUCTION.

(defclass fixnum-sub-instruction (multiple-successors-mixin instruction)
  ())

(defun make-fixnum-sub-instruction (inputs output successors)
  (make-instance 'fixnum-sub-instruction
    :inputs inputs
    :outputs (list output)
    :successors successors))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Instruction FIXNUM-LESS-INSTRUCTION.

(defclass fixnum-less-instruction (multiple-successors-mixin instruction)
  ())

(defun make-fixnum-less-instruction (inputs successors)
  (make-instance 'fixnum-less-instruction
    :inputs inputs
    :outputs '()
    :successors successors))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Instruction FIXNUM-NOT-GREATER-INSTRUCTION.

(defclass fixnum-not-greater-instruction (multiple-successors-mixin instruction)
  ())

(defun make-fixnum-not-greater-instruction (inputs successors)
  (make-instance 'fixnum-not-greater-instruction
    :inputs inputs
    :outputs '()
    :successors successors))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Instruction FIXNUM-EQUAL-INSTRUCTION.

(defclass fixnum-equal-instruction (multiple-successors-mixin instruction)
  ())

(defun make-fixnum-equal-instruction (inputs successors)
  (make-instance 'fixnum-equal-instruction
    :inputs inputs
    :outputs '()
    :successors successors))
