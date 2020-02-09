#|

    Boxer
    Copyright 1985-2020 Andrea A. diSessa and the Estate of Edward H. Lay

    Portions of this code may be copyright 1982-1985 Massachusetts Institute of Technology. Those portions may be
    used for any purpose, including commercial ones, providing that notice of MIT copyright is retained.

    Licensed under the 3-Clause BSD license. You may not use this file except in compliance with this license.

    https://opensource.org/licenses/BSD-3-Clause


                                         +-Data--+
                This file is part of the | BOXER | system
                                         +-------+


        Special key handling for Lispworks for Macintosh


Key input is handled as follows, the underlying window system generates an
implementation specific key event.  This is usually a character object or a
fixnum with defined fields.

The raw key event is then encoded into an intermediate form by the key event
handler, usually by calling on functioned defined in this file.  For a properly
well formed domain of raw key events, no encoding may be neccessary.  This boxer
specific form has the requirement that we be able to extract a unique character
code and character bits for each possible key event.  CHARACTERS with shift bits
are the currency of the event system.

This file bridges the gap between system generated keyboard events and the characters
in the event queue.  The char codes will be used as indices into the key names array by
lookup-key-name in keydef-high.lisp.  The values are accessed from the encoded key event
by the functions input-code and input-bits.  Implementation specific versions of
input-code and input-bits are defined in macros.lisp

For the LWW implementation we have the problem that some of the raw key events have
identical character codes.  The distinguishing factor being that some of the input
chas are EXTENDED-CHARACTERS with FUNCTION-KEY-P set to T.

For the LWM implementation, we need to handle the fact that the function key events
generated by the event system have fairly large values (e.g. #xF700 for the up-arrow-key).
We handle this by remapping function key events into char codes immediately above 256.

Modification History (most recent at top)

 4/21/03 merged current LW and MCL files, no MCL version, updated copyright
11/27/99 started file


|#

(in-package :boxer-window)

;;; the boxer event char-code mapping to BU: symbol key names is communicated to
;;; lookup-key-name via the variable:

(defvar boxer::*LWM-keyboard-key-name-alist* nil)

(defvar *key-name-system-code-alist* nil)

(defvar *gesture-spec-symbol-key-code-alist* nil)

(defvar *lwm-system-char-events* nil)

(defvar *boxer-function-key-code-start* 256)

(defvar *current-function-key-code*)

(defun initialize-function-key-defs ()
  (setq boxer::*LWM-keyboard-key-name-alist* nil
        *key-name-system-code-alist*         nil
        *lwm-system-char-events*             nil
        *gesture-spec-symbol-key-code-alist* '((:kp-enter 13))
        *current-function-key-code* *boxer-function-key-code-start*))

;;; for each function key we need, the system generated char code, the boxer-user symbol
;;; name and the boxer level char code
(defmacro define-lwm-function-key (key-name system-code &optional gspec-symbol)
  (let ((existing (gensym)) (boxer-code (gensym)) (ex-gspec (gensym)))
    `(let ((,existing (assoc ',key-name boxer::*lwm-keyboard-key-name-alist*))
           (,boxer-code (or (cadr (assoc ',key-name *key-name-system-code-alist*))
                            (prog1 (incf *current-function-key-code*)
                              (push (list ',key-name *current-function-key-code*)
                                    *key-name-system-code-alist*)))))
       (cond ((null ,existing)
              (push (list ',key-name ,boxer-code) boxer::*lwm-keyboard-key-name-alist*))
             (T (setf (cadr ,existing) ,boxer-code)))
       (unless (null ,gspec-symbol)
         (let ((,ex-gspec (assoc ,gspec-symbol *gesture-spec-symbol-key-code-alist*)))
           (cond ((null ,ex-gspec)
                  (push (list ',gspec-symbol ,boxer-code)
                        *gesture-spec-symbol-key-code-alist*))
                 (t (setf (cadr ,ex-gspec) ,boxer-code)))))
       (unless (member ,system-code *lwm-system-char-events* :test #'=)
         (push ,system-code *lwm-system-char-events*))
       ,boxer-code)))

(defun boxer-code-from-gspec-symbol (gs)
  (cadr (assoc gs *gesture-spec-symbol-key-code-alist*)))

(initialize-function-key-defs)

(define-lwm-function-key BU::UP-ARROW-KEY COCOA:NS-UP-ARROW-FUNCTION-KEY :up)
(define-lwm-function-key BU::DOWN-ARROW-KEY COCOA:NS-DOWN-ARROW-FUNCTION-KEY :down)
(define-lwm-function-key BU::LEFT-ARROW-KEY COCOA:NS-LEFT-ARROW-FUNCTION-KEY :left)
(define-lwm-function-key BU::RIGHT-ARROW-KEY COCOA:NS-RIGHT-ARROW-FUNCTION-KEY :right)

(define-lwm-function-key BU::F1-KEY COCOA:NS-F1-FUNCTION-KEY :f1)
(define-lwm-function-key BU::F2-KEY COCOA:NS-F2-FUNCTION-KEY :f2)
(define-lwm-function-key BU::F3-KEY COCOA:NS-F3-FUNCTION-KEY :F3)
(define-lwm-function-key BU::F4-KEY COCOA:NS-F4-FUNCTION-KEY :F4)
(define-lwm-function-key BU::F5-KEY COCOA:NS-F5-FUNCTION-KEY :F5)
(define-lwm-function-key BU::F6-KEY COCOA:NS-F6-FUNCTION-KEY :F6)
(define-lwm-function-key BU::F7-KEY COCOA:NS-F7-FUNCTION-KEY :F7)
(define-lwm-function-key BU::F8-KEY COCOA:NS-F8-FUNCTION-KEY :F8)
(define-lwm-function-key BU::F9-KEY COCOA:NS-F9-FUNCTION-KEY :F9)
(define-lwm-function-key BU::F10-KEY COCOA:NS-F10-FUNCTION-KEY :F10)
(define-lwm-function-key BU::F11-KEY COCOA:NS-F11-FUNCTION-KEY :F11)
(define-lwm-function-key BU::F12-KEY COCOA:NS-F12-FUNCTION-KEY :F12)
(define-lwm-function-key BU::F13-KEY COCOA:NS-F13-FUNCTION-KEY :F13)
(define-lwm-function-key BU::F14-KEY COCOA:NS-F14-FUNCTION-KEY :F14)
(define-lwm-function-key BU::F15-KEY COCOA:NS-F15-FUNCTION-KEY :F15)
(define-lwm-function-key BU::F16-KEY COCOA:NS-F16-FUNCTION-KEY :F16)
(define-lwm-function-key BU::F17-KEY COCOA:NS-F17-FUNCTION-KEY :F17)
(define-lwm-function-key BU::F18-KEY COCOA:NS-F18-FUNCTION-KEY :F18)
(define-lwm-function-key BU::F19-KEY COCOA:NS-F19-FUNCTION-KEY :F19)
(define-lwm-function-key BU::F20-KEY COCOA:NS-F20-FUNCTION-KEY :F20)
(define-lwm-function-key BU::F21-KEY COCOA:NS-F21-FUNCTION-KEY :F21)
(define-lwm-function-key BU::F22-KEY COCOA:NS-F22-FUNCTION-KEY :F22)
(define-lwm-function-key BU::F23-KEY COCOA:NS-F23-FUNCTION-KEY :F23)
(define-lwm-function-key BU::F24-KEY COCOA:NS-F24-FUNCTION-KEY :F24)
(define-lwm-function-key BU::F25-KEY COCOA:NS-F25-FUNCTION-KEY :F25)
(define-lwm-function-key BU::F26-KEY COCOA:NS-F26-FUNCTION-KEY :F26)
(define-lwm-function-key BU::F27-KEY COCOA:NS-F27-FUNCTION-KEY :F27)
(define-lwm-function-key BU::F28-KEY COCOA:NS-F28-FUNCTION-KEY :F28)
(define-lwm-function-key BU::F29-KEY COCOA:NS-F29-FUNCTION-KEY :F29)
(define-lwm-function-key BU::F30-KEY COCOA:NS-F30-FUNCTION-KEY :F30)
(define-lwm-function-key BU::F31-KEY COCOA:NS-F31-FUNCTION-KEY :F31)
(define-lwm-function-key BU::F32-KEY COCOA:NS-F32-FUNCTION-KEY :F32)
(define-lwm-function-key BU::F33-KEY COCOA:NS-F33-FUNCTION-KEY :F33)
(define-lwm-function-key BU::F34-KEY COCOA:NS-F34-FUNCTION-KEY :F34)
(define-lwm-function-key BU::F35-KEY COCOA:NS-F35-FUNCTION-KEY :F35)

(define-lwm-function-key BU::INSERT-KEY COCOA:NS-INSERT-FUNCTION-KEY)
(define-lwm-function-key BU::DELETE-KEY COCOA:NS-DELETE-FUNCTION-KEY)

(define-lwm-function-key BU::HOME-KEY COCOA:NS-HOME-FUNCTION-KEY :home)

(define-lwm-function-key BU::BEGIN-KEY COCOA:NS-BEGIN-FUNCTION-KEY)
(define-lwm-function-key BU::END-KEY COCOA:NS-END-FUNCTION-KEY :end)

(define-lwm-function-key BU::PAGE-UP-KEY COCOA:NS-PAGE-UP-FUNCTION-KEY :prior)
(define-lwm-function-key BU::PAGE-DOWN-KEY COCOA:NS-PAGE-DOWN-FUNCTION-KEY :next)

(define-lwm-function-key BU::PRINT-SCREEN-KEY COCOA:NS-PRINT-SCREEN-FUNCTION-KEY)
(define-lwm-function-key BU::SCROLL-LOCK-KEY COCOA:NS-SCROLL-LOCK-FUNCTION-KEY)
(define-lwm-function-key BU::PAUSE-KEY COCOA:NS-PAUSE-FUNCTION-KEY)

(define-lwm-function-key BU::SYS-REQ-KEY COCOA:NS-SYS-REQ-FUNCTION-KEY)
(define-lwm-function-key BU::BREAK-KEY COCOA:NS-BREAK-FUNCTION-KEY)
(define-lwm-function-key BU::RESET-KEY COCOA:NS-RESET-FUNCTION-KEY)
(define-lwm-function-key BU::STOP-KEY COCOA:NS-STOP-FUNCTION-KEY)

(define-lwm-function-key BU::MENU-KEY COCOA:NS-MENU-FUNCTION-KEY)
(define-lwm-function-key BU::USER-KEY COCOA:NS-USER-FUNCTION-KEY)
(define-lwm-function-key BU::SYSTEM-KEY COCOA:NS-SYSTEM-FUNCTION-KEY)
(define-lwm-function-key BU::PRINT-KEY COCOA:NS-PRINT-FUNCTION-KEY)

(define-lwm-function-key BU::CLEAR-LINE-KEY COCOA:NS-CLEAR-LINE-FUNCTION-KEY :clear-line)
(define-lwm-function-key BU::CLEAR-DISPLAY-KEY COCOA:NS-CLEAR-DISPLAY-FUNCTION-KEY)

(define-lwm-function-key BU::INSERT-LINE-KEY COCOA:NS-INSERT-LINE-FUNCTION-KEY)
(define-lwm-function-key BU::DELETE-LINE-KEY COCOA:NS-DELETE-LINE-FUNCTION-KEY)

(define-lwm-function-key BU::INSERT-CHAR-KEY COCOA:NS-INSERT-CHAR-FUNCTION-KEY)
(define-lwm-function-key BU::DELETE-CHAR-KEY COCOA:NS-DELETE-CHAR-FUNCTION-KEY)

(define-lwm-function-key BU::PREV-KEY COCOA:NS-PREV-FUNCTION-KEY)
(define-lwm-function-key BU::NEXT-KEY COCOA:NS-NEXT-FUNCTION-KEY)

(define-lwm-function-key BU::SELECT-KEY COCOA:NS-SELECT-FUNCTION-KEY)
(define-lwm-function-key BU::EXECUTE-KEY COCOA:NS-EXECUTE-FUNCTION-KEY)
(define-lwm-function-key BU::UNDO-KEY COCOA:NS-UNDO-FUNCTION-KEY)
(define-lwm-function-key BU::REDO-KEY COCOA:NS-REDO-FUNCTION-KEY)

(define-lwm-function-key BU::FIND-KEY COCOA:NS-FIND-FUNCTION-KEY)
(define-lwm-function-key BU::HELP-KEY COCOA:NS-HELP-FUNCTION-KEY)
(define-lwm-function-key BU::MODE-SWITCH-KEY COCOA:NS-MODE-SWITCH-FUNCTION-KEY)

;; The test for whether a system level key code needs to be remapped is:
(defun remap-char? (char) (>= (char-code char) #xf700))

;; the remapping is performed by:
(defun remap-char (char)
  (code-char (+ (- (char-code char) #xf700) *boxer-function-key-code-start*)))

;; the external interface (from boxwin)
;; the key-handler in boxwin-lw uses this to generate the correct input event
(defun input-char->key-event (char)
  (if (remap-char? char) (remap-char char) char))

;; gesture modifiers are:
;; 1 = SHIFT, 2 = CONTROL, 4 = META, 8 = HYPER (the apple command key)
(defun convert-gesture-spec-modifier (gesture)
  (let ((rawgm (sys:gesture-spec-modifiers gesture)))
    ;; effectively ignoring the shift bit, but keeping the hyper bit distinct
    ;(ash rawgm -1)
    ;; we could convert the command key to control here....
    ;; lookup table is fastest
    (svref #(0 1 2 3 1 1 2 3) (ash rawgm -1))
    ))

(defun input-gesture->key-event (gesture)
  (let ((data (sys::gesture-spec-data gesture)))
    (cond ((numberp data)
           (boxer::make-char (code-char data) (convert-gesture-spec-modifier gesture)))
          ((symbolp data)
           (let ((ccode (boxer-code-from-gspec-symbol data)))
             (cond ((null ccode) ; gak!
                    (error "Can't convert ~S to input character" data))
                   (t (boxer::make-char (code-char ccode)
                                        (convert-gesture-spec-modifier gesture)))))))))


