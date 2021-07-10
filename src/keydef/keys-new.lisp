;;;;  ;; -*- Mode:LISP;Syntax: Common-Lisp; Package:BOXER;-*-
;;;;
;;;;      Boxer
;;;;      Copyright 1985-2020 Andrea A. diSessa and the Estate of Edward H. Lay
;;;;
;;;;      Portions of this code may be copyright 1982-1985 Massachusetts Institute of Technology. Those portions may be
;;;;      used for any purpose, including commercial ones, providing that notice of MIT copyright is retained.
;;;;
;;;;      Licensed under the 3-Clause BSD license. You may not use this file except in compliance with this license.
;;;;
;;;;      https://opensource.org/licenses/BSD-3-Clause
;;;;
;;;;
;;;;                                           +-Data--+
;;;;                  This file is part of the | BOXER | system
;;;;                                           +-------+
;;;;
;;;;
;;;;      New (and hopefully final) key bindings
;;;;
;;;;
;;;;  Modification History (most recent at top)
;;;;
;;;;   2/05/07 changed #+ mcl's and lwwins to apple and win32 - in this file they refer
;;;;           to physical devices, also "apple" seems to be the only feature that digitool
;;;;           and lispworks share for referring to the mac.
;;;;   6/06/05 added escape-key binding for com-abort
;;;;   1/09/04 added com-hardcopy-lw-window for lispworks ctrl-P
;;;;  10/20/04 removed escape key binding (com-christmas-tree)
;;;;   4/21/03 merged current LW and MCL files
;;;;   9/02/02 changed ctrl-~ binding from com-unmodify-document to
;;;;           com-toggle-modified-flag
;;;;   5/22/01 added backspace equivalents for {cmd, opt}-delete and search mode delete
;;;;   2/15/01 merged current LW and MCL files
;;;;  12/20/00 added com-fill-box on c-m-f-key
;;;;  11/04/00 added com-follow-mouse to mouse-click-on-sprite for LWWIN
;;;;           com-mouse-br-pop-up to mouse-click-on-bottom-right
;;;;   7/06/00 added LWWIN mouse-double-click binding, other double click tuning
;;;;   3/26/00 more PC binding fine tuning
;;;;  12/05/99 added PC mouse bindings, reorganized mice bindings into functional groups
;;;;  11/28/99 added lispworks PC bindings
;;;;  01/06/99 added mac bindings for HOME, END, PAGE-UP, PAGE-DOWN and DELX keys
;;;;  01/06/99 started logging changes: source = boxer version 2.3beta+2
;;;;

(in-package :boxer)


;;;;; New Key Bindings


;;; standard keys


;;; Defines all the "normal" (no ctrl- or meta- or super- or...) keys
;;; to be self inserting
(let ((vanilla-key-codes-not-to-define
       '#.(mapcar #'char-code '(#\| #\[ #\] #\{ #\} #\return #\tab #\delete))))
  (dotimes (key-code #o177)
    (let ((char-to-insert (code-char key-code)))
      (unless (member key-code vanilla-key-codes-not-to-define)
  (let ((key-name (lookup-key-name key-code 0)))
    (when (null key-name)
      (error "Key name for key ~D was not found" key-code))
    (boxer-eval::defboxer-key-internal
     key-name
     #'(lambda ()
               ;(reset-region)
               ;; mac behavior instead...
               (let ((r (or *region-being-defined* (get-current-region))))
                 (unless (null r) (editor-kill-region r)))
         (with-multiple-execution
       #-opengl(add-redisplay-clue (point-row) ':insert)
     (insert-cha *point* char-to-insert :moving))
               (mark-file-box-dirty (point-row))
               boxer-eval::*novalue*))
    (boxer-command-define
     key-name
     (format nil
       "Inserts the ~C character at the cursor."
       char-to-insert)))))))

;; the return of parens
(defself-inserting-key BOXER-USER::|(-KEY| #\()
(defself-inserting-key BOXER-USER::|)-KEY| #\))


(boxer-eval::defboxer-key (bu::g-key 1) com-abort)
;; added escape 6/5/05
(boxer-eval::defboxer-key bu::escape-key com-abort)

(boxer-eval::defboxer-key bu::space-key com-space)

(boxer-eval::defboxer-key bu::return-key com-return)

;; emacsy (optional)
(boxer-eval::defboxer-key (bu::a-key 1) com-beginning-of-row)
(boxer-eval::defboxer-key (bu::e-key 1) com-end-of-row)

;; these are shadowed farther down by the font change keys
(boxer-eval::defboxer-key (bu::<-key 2) com-beginning-of-box)
(boxer-eval::defboxer-key (bu::>-key 2) com-end-of-box)

(boxer-eval::defboxer-key (bu::<-key 3) com-goto-top-level)

(boxer-eval::defboxer-key (bu::k-key 1) com-kill-to-end-of-row)


;;;; [] Making Boxes

(boxer-eval::defboxer-key bu::[-key com-make-and-enter-box)

(boxer-eval::defboxer-key bu::{-key com-make-and-enter-data-box)

(boxer-eval::defboxer-key (bu::t-key 2) com-make-turtle-box)

(boxer-eval::defboxer-key (bu::s-key 2) com-make-sprite-box)

(boxer-eval::defboxer-key (bu::g-key 2) com-make-graphics-box)

(boxer-eval::defboxer-key (bu::p-key 2) com-place-port)

(boxer-eval::defboxer-key (bu::p-key 3) com-make-port)


;;;; [] Cutting and Pasting

(boxer-eval::defboxer-key (bu::x-key 1) com-cut-region)

(boxer-eval::defboxer-key (bu::c-key 1) com-copy-region)

(boxer-eval::defboxer-key (bu::v-key 1) com-yank)

(boxer-eval::defboxer-key (bu::v-key 2) com-retrieve)
(boxer-eval::defboxer-key (bu::y-key 1) com-retrieve)

;;;; [] Other Important

(boxer-eval::defboxer-key (bu::.-key 1) com-abort)

;; Find
(boxer-eval::defboxer-key (bu::f-key 1) com-search-forward)

(boxer-eval::defboxer-key (bu::f-key 2) com-search-backward)

(eval-when (eval load)
  (let ((vanilla-key-codes-not-to-define '#.(mapcar #'char-code
                '(#\| #\[ #\]))))
    (dotimes (key-code #o177)
      (let ((char-to-insert (code-char key-code)))
  (unless (member key-code vanilla-key-codes-not-to-define)
    (let ((key-name (lookup-key-name key-code 0)))
      (when (null key-name)
        (error "Key name for key ~D was not found" key-code))
      (defboxer-mode-key-internal key-name (search-mode)
        #'(lambda () (com-search-char char-to-insert)
      boxer-eval::*novalue*)))))))
  )

(defsearch-mode-key bu::[-key com-search-doit-box)

(defsearch-mode-key bu::{-key com-search-data-box)

(defsearch-mode-key (bu::space-key 2) com-search-port)

(defsearch-mode-key bu::\|-key com-search-named-box)
(defsearch-mode-key bu::]-key com-search-exit-named-box)
(defsearch-mode-key bu::}-key com-search-exit-named-box)

(defsearch-mode-key (bu::f-key 1) com-search-forward-again)

(defsearch-mode-key (bu::f-key 2) com-search-backward-again)

(defsearch-mode-key bu::escape-key  com-end-search)
(defsearch-mode-key (bu::\'-key 1) com-quote-search-char)
(defsearch-mode-key (bu::\"-key 1) com-quote-search-char)
(defsearch-mode-key (bu::g-key 1)  com-abort-search)
(defsearch-mode-key bu::delete-key  com-delete-search-char)
(defsearch-mode-key bu::backspace-key  com-delete-search-char)
(defsearch-mode-key (bu::^-key 1)  com-expand-search)

(defsearch-mode-key (bu::.-key 1) com-abort-search)
(defsearch-mode-key bu::help-key com-search-help)
(defsearch-mode-key (bu::r-key 1) com-force-redisplay-all)


;; Doit
(boxer-eval::defboxer-key bu::line-key com-doit-now)
;(boxer-eval::defboxer-key bu::shift-return-key com-doit-now)

;; Step
(boxer-eval::defboxer-key (bu::line-key 1) com-step)
(boxer-eval::defboxer-key (bu::line-key 2) com-step) ; not approved
(boxer-eval::defboxer-key (bu::return-key 1) com-doit-now)

;; Name-Tab
(boxer-eval::defboxer-key bu::\|-key com-name-box)

;; Unbox
(boxer-eval::defboxer-key (bu::@-key 1) com-unboxify)

;; Refresh Display
(boxer-eval::defboxer-key (bu::r-key 1) com-force-redisplay)

;; Help

(boxer-eval::defboxer-key bu::help-key com-help)
(boxer-eval::defboxer-key (bu::help-key 1) com-prompt)
(boxer-eval::defboxer-key (bu::help-key 2) com-document-key)
;; on the PC the Insert-key is in the same place as the mac help key
(boxer-eval::defboxer-key bu::insert-key com-help)
(boxer-eval::defboxer-key (bu::insert-key 1) com-prompt)
(boxer-eval::defboxer-key (bu::insert-key 2) com-document-key)

(boxer-eval::defboxer-key (bu::h-key 1) com-help)

;; Toggle Transparency
(boxer-eval::defboxer-key (bu::t-key 1) com-toggle-box-transparency)

;; Print Screen
(boxer-eval::defboxer-key (bu::p-key 1) com-print-screen)

;; Zoom
(boxer-eval::defboxer-key (bu::z-key 1) com-move-to-port-target)

; removed 10/20/04
;(boxer-eval::defboxer-key bu::escape-key com-christmas-tree)

(boxer-eval::defboxer-key (bu::\'-key 1) com-quote-self-insert)
(boxer-eval::defboxer-key (bu::\"-key 1) com-quote-self-insert)

;;; Characters
(boxer-eval::defboxer-key bu::left-arrow-key com-backward-cha)
(boxer-eval::defboxer-key bu::Right-Arrow-key com-forward-cha)

;; Words
(boxer-eval::defboxer-key (bu::Left-Arrow-key 1) com-backward-word)
(boxer-eval::defboxer-key (bu::Right-Arrow-key 1) com-forward-word)

;; Lines
(boxer-eval::defboxer-key bu::up-arrow-key com-previous-row)
(boxer-eval::defboxer-key bu::down-arrow-key com-next-row)
(boxer-eval::defboxer-key (bu::Left-Arrow-key 2) com-beginning-of-row)
(boxer-eval::defboxer-key (bu::Right-Arrow-key 2) com-end-of-row)

;; Box Scroll
(boxer-eval::defboxer-key (bu::up-arrow-key 1) com-scroll-up-one-screen-box)
(boxer-eval::defboxer-key (bu::down-arrow-key 1) com-scroll-dn-one-screen-box)
(boxer-eval::defboxer-key bu::page-up-key com-scroll-up-one-screen-box)
(boxer-eval::defboxer-key bu::page-down-key com-scroll-dn-one-screen-box)

;; Global Box
(boxer-eval::defboxer-key (bu::up-arrow-key 2) com-beginning-of-box)
(boxer-eval::defboxer-key (bu::down-arrow-key 2) com-end-of-box)
(boxer-eval::defboxer-key bu::home-key com-beginning-of-box)
(boxer-eval::defboxer-key bu::end-key  com-end-of-box)

;; Among Box Navigation
(boxer-eval::defboxer-key (bu::up-arrow-key 3) com-shrink-box)
(boxer-eval::defboxer-key (bu::right-arrow-key 3) com-enter-next-box)
(boxer-eval::defboxer-key (bu::left-arrow-key 3) com-enter-previous-box)

(boxer-eval::defboxer-key bu::tab-key com-move-to-next-box)
;(boxer-eval::defboxer-key bu::shift-tab-key com-move-to-previous-box) ; can't generate shift-TAB
(boxer-eval::defboxer-key (bu::tab-key 1) com-enter-next-box)
(boxer-eval::defboxer-key (bu::tab-key 2) com-enter-previous-box)

(boxer-eval::defboxer-key bu::]-key com-exit-box)
(boxer-eval::defboxer-key bu::}-key com-shrink-box)


;;;; [] Deleting

(boxer-eval::defboxer-key bu::delete-key com-rubout)
;;; by popular demand...
(boxer-eval::defboxer-key bu::backspace-key com-rubout)
(boxer-eval::defboxer-key (bu::backspace-key 1) com-rubout)

(boxer-eval::defboxer-key (bu::d-key 1) com-delete)
#+apple (boxer-eval::defboxer-key bu::delx-key com-delete)
#+lispworks (boxer-eval::defboxer-key bu::delete-key com-delete)

(boxer-eval::defboxer-key (bu::delete-key 2) com-rubout-word)
(boxer-eval::defboxer-key (bu::delete-key 1) com-delete-word)

(boxer-eval::defboxer-key (bu::backspace-key 2) com-rubout-word)
(boxer-eval::defboxer-key (bu::backspace-key 1) com-delete-word)
#+apple (boxer-eval::defboxer-key (bu::delx-key 1) com-delete-word)
#+apple (boxer-eval::defboxer-key (bu::delx-key 2) com-delete-word)
#+lispworks (boxer-eval::defboxer-key (bu::delete-key 1) com-delete-word)
#+lispworks (boxer-eval::defboxer-key (bu::delete-key 2) com-delete-word)

(boxer-eval::defboxer-key (bu::delete-key 3) com-delete-line)
(boxer-eval::defboxer-key (bu::backspace-key 3) com-delete-line)

;;;; [] Format and Caps

;(boxer-eval::defboxer-key (bu::i-key 1) com-italics)
;(boxer-eval::defboxer-key (bu::b-key 1) com-boldface)

;;; and case
(boxer-eval::defboxer-key (bu::c-key 2) com-capitalize-word)
(boxer-eval::defboxer-key (bu::u-key 2) com-uppercase-word)
(boxer-eval::defboxer-key (bu::l-key 2) com-lowercase-word)


;;;; saving/going to locations

(boxer-eval::defboxer-key (bu::space-key 1) com-set-mark)
(boxer-eval::defboxer-key (bu::space-key 2) com-goto-previous-place)

(boxer-eval::defboxer-key (bu::x-key 2) com-exchange-point-and-mark)

(boxer-eval::defboxer-key (bu::/-key 1) com-point-to-register)
(boxer-eval::defboxer-key (bu::/-key 2) com-register-to-point)
(boxer-eval::defboxer-key (bu::j-key 1) com-register-to-point)

;;;; [] Miscellaneous

(boxer-eval::defboxer-key (bu::return-key 2) com-open-line)

(boxer-eval::defboxer-key (bu::f-key 3) com-fill-box)

;;; Defines all the "control" (ctrl-, meta-, or ctrl-meta- ) number
;;; keys to act as a numeric argument

;; sgithens TODO Put this back in once the control bits are fixed.
;; (dotimes (control-bits 3)  ; note the 1+ further down
;;   (do ((key-code #o60 (1+ key-code)))
;;       ((= key-code #o72))
;;     (let ((key-name (lookup-key-name key-code (1+ control-bits))))
;;       (when (null key-name)
;; 	(error "Key name for key ~d was not found" key-code))
;;       (boxer-eval::defboxer-key-internal
;; 	  key-name
;; 	  (intern (symbol-format nil "COM-INCREMENT-NUMERIC-ARG-BY-~D"
;; 			  (- key-code #o60)))))))

(boxer-eval::defboxer-key (bu::?-key 1) com-prompt)
(boxer-eval::defboxer-key (bu::?-key 2) com-document-key)
(boxer-eval::defboxer-key (bu::?-key 3) com-document-key)

(boxer-eval::defboxer-key (bu::v-key 3) com-toggle-vanilla-mode)


;;; files

(boxer-eval::defboxer-key (bu::s-key 1) com-save-document)

(boxer-eval::defboxer-key (bu::o-key 1) com-open-box-file)

(boxer-eval::defboxer-key (bu::n-key 2) com-new-file-box)

(boxer-eval::defboxer-key (bu::~-key 1) com-toggle-modified-flag) ;com-unmodify-document

;;;
;;; MICE
;;;
;;; Possible Mouse click types that can be used depending on device input configuration.
;;;   mouse-click-on-, command-mouse-click-on-, option-mouse-click-on-
;;;   alt-mouse-click-on-, ctrl-mouse-click-on-, mouse-double-click-on-
;;;   mouse-right-click-on-, ctrl-mouse-right-click-on-, alt-mouse-right-click-on-
;;;   option-mouse-click-on-, command-mouse-click-on-
;;;
;;; mouse-click-on-graphics, ctrl-mouse-click-on-graphics, alt-mouse-click-on-graphics
;;; ctrl-mouse-right-click-on-graphics, alt-mouse-right-click-on-graphics

;;;
;;; plain clicks on middle of boxes
;;;

;; 2021-02-24 These have been consolidated now in to one set of bindings for MacOS, Windows, Linux
;; The ctrl click bindings were previously set to Command clicks on MacOS, although that had actually
;; been binding to ctrl. Once we fix Command bindings, perhaps these bindings should be reviewed,
;; especially since ctrl-click is often used on MacOS to mimic a right click.

(boxer-eval::defboxer-key bu::mouse-click com-mouse-define-region)

(boxer-eval::defboxer-key bu::ctrl-mouse-click  com-mouse-expand-box) ; was also previously listed as Command on MacOS

(boxer-eval::defboxer-key bu::option-mouse-click  com-mouse-collapse-box)
(boxer-eval::defboxer-key bu::alt-mouse-click  com-mouse-collapse-box)

(boxer-eval::defboxer-key bu::option-mouse-double-click com-mouse-shrink-box)
(boxer-eval::defboxer-key bu::alt-mouse-double-click com-mouse-shrink-box)

(boxer-eval::defboxer-key bu::mouse-double-click com-mouse-doit-now)

(boxer-eval::defboxer-key bu::ctrl-mouse-double-click com-mouse-set-outermost-box) ; was also previously listed as Command on MacOS

(boxer-eval::defboxer-key bu::mouse-click-on-graphics com-noop)

(boxer-eval::defboxer-key bu::option-mouse-click-on-graphics com-mouse-collapse-box)
(boxer-eval::defboxer-key bu::alt-mouse-click-on-graphics com-mouse-collapse-box)

;; TODO 2021-02-24 these should be revisited since graphics boxes can't be fullscreened
(boxer-eval::defboxer-key bu::ctrl-mouse-click-on-graphics com-mouse-expand-box) ; was also previously listed as Command on MacOS
(boxer-eval::defboxer-key bu::ctrl-mouse-double-click-on-graphics com-mouse-set-outermost-box)

(boxer-eval::defboxer-key bu::option-mouse-double-click-on-graphics com-mouse-shrink-box)
(boxer-eval::defboxer-key bu::alt-mouse-double-click-on-graphics com-mouse-shrink-box)

(boxer-eval::defboxer-key bu::mouse-double-click com-mouse-doit-now)

;; This was previously used in windows...
;; (boxer-eval::defboxer-key bu::mouse-click       com-mouse-move-point)

;; sprite clicks
(boxer-eval::defboxer-key bu::mouse-click-on-sprite com-sprite-follow-mouse)

;;;
;;; Box Border Mouse Commands
;;;
;;;  Top Right Corner:
;;;    Click: Expand box to next size up
;;;    Double Click: Full Screen
;;;    Right Click: Context Menu

(boxer-eval::defboxer-key bu::mouse-click-on-top-right com-mouse-tr-corner-expand-box)
(boxer-eval::defboxer-key bu::mouse-double-click-on-top-right com-mouse-set-outermost-box)

(boxer-eval::defboxer-key bu::ctrl-mouse-click-on-top-right  com-mouse-boxsize-closet-properties-pop-up)
(boxer-eval::defboxer-key bu::mouse-right-click-on-top-right  com-mouse-boxsize-closet-properties-pop-up)

;;;  Top Left Corner:
;;;    Click: Shrink to next size down
;;;    Double Click: Supershrink
;;;    Right Click: Context Menu

(boxer-eval::defboxer-key bu::mouse-click-on-top-left com-mouse-tl-corner-collapse-box)
(boxer-eval::defboxer-key bu::mouse-double-click-on-top-left com-mouse-super-shrink-box)

(boxer-eval::defboxer-key bu::mouse-right-click-on-top-left com-mouse-boxsize-closet-properties-pop-up)
(boxer-eval::defboxer-key bu::ctrl-mouse-click-on-top-left com-mouse-boxsize-closet-properties-pop-up)

;;;  Bottom Left Corner:
;;;    Click: Flip to text/graphics. Currently requires holding
;;;    Double Click: Nothing
;;;    Right Click: Context Menu

(boxer-eval::defboxer-key bu::mouse-click-on-bottom-left com-mouse-bl-corner-toggle-box-view)

(boxer-eval::defboxer-key bu::mouse-right-click-on-bottom-left com-mouse-box-types-pop-up)
(boxer-eval::defboxer-key bu::ctrl-mouse-click-on-bottom-left com-mouse-box-types-pop-up)

;;;  Bottom Right Corner:
;;;    Click/Drag: Resize
;;;    Double Click: Switch back to automatic size
;;;    Right Click: Context Menu

(boxer-eval::defboxer-key bu::mouse-click-on-bottom-right com-mouse-br-resize-box)
;; (boxer-eval::defboxer-key bu::mouse-right-click-on-bottom-right com-mouse-br-pop-up)

;;;  Type Tab:
;;;    Click: Flip between Doit/Graphics, requires holding
;;;    Double Click: Nothing
;;;    Right Click: Context Menu

(boxer-eval::defboxer-key bu::mouse-click-on-type   com-mouse-border-toggle-type)
;; (boxer-eval::defboxer-key bu::mouse-right-click-on-type com-mouse-type-tag-pop-up)

;;;
;;; Box Name Row
;;;

(boxer-eval::defboxer-key bu::mouse-click-on-name-handle com-mouse-border-name-box)
(boxer-eval::defboxer-key bu::mouse-click-on-name         com-mouse-move-point)

;;;
;;; Scrolling
;;;

(boxer-eval::defboxer-key bu::mouse-click-on-scroll-bar                com-mouse-scroll-box)

(boxer-eval::defboxer-key bu::ctrl-mouse-click-on-scroll-bar        com-mouse-page-scroll-box) ;; was previously Command on MacOS
(boxer-eval::defboxer-key bu::option-mouse-click-on-scroll-bar         com-mouse-page-scroll-box)
(boxer-eval::defboxer-key bu::alt-mouse-click-on-scroll-bar         com-mouse-page-scroll-box)

(boxer-eval::defboxer-key bu::mouse-double-click-on-scroll-bar         com-mouse-limit-scroll-box)
(boxer-eval::defboxer-key bu::ctrl-mouse-right-click-on-scroll-bar com-mouse-limit-scroll-box)
(boxer-eval::defboxer-key bu::alt-mouse-right-click-on-scroll-bar  com-mouse-limit-scroll-box)
(boxer-eval::defboxer-key bu::option-mouse-double-click-on-scroll-bar  com-mouse-limit-scroll-box)
(boxer-eval::defboxer-key bu::ctrl-mouse-double-click-on-scroll-bar com-mouse-limit-scroll-box) ;; was previously Command on MacOS


;;;; temporary

(boxer-eval::defboxer-key bu::F9-key com-toggle-closets)
(boxer-eval::defboxer-key bu::R1-key com-prompt)
#+apple(boxer-eval::defboxer-key (bu::escape-key 1) com-break)
#+lispworks (boxer-eval::defboxer-key (bu::escape-key 1) com-break)
#+(and lispworks win32) (boxer-eval::defboxer-key bu::pause-key com-break)
#+(and lispworks macosx)(boxer-eval::defboxer-key (bu::F13-key 3) com-break)
;; adds pause breaks when in dribble recording mode
;; recording mode checks for this particular keypress (can't look
;; for names at the recording level)
#+apple
(boxer-eval::defboxer-key (bu::f15-key 3) com-noop)
#+apple
(boxer-eval::defboxer-key (bu::f14-key 3) com-noop)
;;;
(eval-when (load)
  (boxer-eval::boxer-toplevel-set 'bu::new-box-properties (make-new-box-properties-box))
  )


(defun use-mouse2021-keybindings (use-mouse2021)
  "During this Work In Progress phase we are supported both the old mouse behavior and the
   new. This switches the mouse bindings back and forth based on the input boolean, T being
   the new bindings."
  (cond (use-mouse2021
         ;; "Setting up 2021 Mouse bindings"
         (boxer-eval::defboxer-key bu::mouse-down com-mouse-define-region)
         (boxer-eval::defboxer-key bu::mouse-click com-noop)
         (boxer-eval::defboxer-key bu::mouse-up com-noop)

         (boxer-eval::defboxer-key bu::mouse-down-on-graphics com-noop)
         (boxer-eval::defboxer-key bu::mouse-up-on-graphics com-noop)

         (boxer-eval::defboxer-key bu::mouse-down-on-sprite com-sprite-follow-mouse)
         (boxer-eval::defboxer-key bu::mouse-down-on-bottom-right com-mouse-br-resize-box)

         (boxer-eval::defboxer-key bu::mouse-click-on-sprite com-noop)
         (boxer-eval::defboxer-key bu::mouse-click-on-bottom-right com-noop)
        )
        (t
         ;; "Using old school mouse bindings"
         (boxer-eval::defboxer-key bu::mouse-down com-noop)
         (boxer-eval::defboxer-key bu::mouse-click com-mouse-define-region)
         (boxer-eval::defboxer-key bu::mouse-up com-noop)

         (boxer-eval::defboxer-key bu::mouse-down-on-graphics com-noop)
         (boxer-eval::defboxer-key bu::mouse-up-on-graphics com-noop)

         (boxer-eval::defboxer-key bu::mouse-down-on-sprite com-noop)
         (boxer-eval::defboxer-key bu::mouse-down-on-bottom-right com-noop)

         (boxer-eval::defboxer-key bu::mouse-click-on-sprite com-sprite-follow-mouse)
         (boxer-eval::defboxer-key bu::mouse-click-on-bottom-right com-mouse-br-resize-box)
        ))
)
