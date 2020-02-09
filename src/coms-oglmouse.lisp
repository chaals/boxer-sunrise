;; -*- Mode:LISP;Syntax:Common-Lisp; Package:BOXER; -*-

#|

 $Header: coms-mouse.lisp,v 1.0 90/01/24 22:08:41 boxer Exp $



 $Log:	coms-mouse.lisp,v $
;;;Revision 1.0  90/01/24  22:08:41  boxer
;;;Initial revision
;;;






        Copyright 1989 - 1998 Regents of the University of California

 Enhancements and Modifications Copyright 1998 - 2009 Pyxisystems LLC


                                         +-Data--+
                This file is part of the | BOXER | system
                                         +-------+


	   This file contains top level definitions for
	   the set of BOXER Editor Mouse Commands.


Modification History (most recent at top)

 9/24/12 removed fixnum assumptions in: com-mouse-define-region, com-mouse-resize-box,
            mouse-corner-tracking, com-mouse-border-toggle-type
            com-mouse-scroll-box, com-mouse-page-scroll, com-mouse-limit-scroll-box,
            mouse-smooth-scroll-internal, mouse-in-v-scroll-bar-internal
 8/18/11 removed drawing-on-window from com-mouse-resize-box (apparently opengl::rendering-on is
         not, or has troubles with being, reentrant)
 8/11/11 com-mouse-resize-box
 5/20/09 scroll-bar commands
 2/27/07 border coms changed to use new track mouse paradigm
         (redisplay-cursor) => (repaint-cursor), (redisplay) => (repaint)
         remove all (add-redisplay-clue 's
11/15/03 com-mouse-define-region uses restore-point-position to handle possible
         munging of the destination
10/29/03 removed flush-port-buffer from com-mouse-define-region, graphics flush
         now occurs as part of the with-mouse-tracking macro
         #+ graphics-flush changed to (force-graphics-output) in
         mouse-{smooth-scroll,line-scroll,in-scroll-bar}-internal
10/15/03 display-force-output changed to force-graphics-output in
         com-mouse-resize-box & com-christmas-tree
10/26/03 flush-port-buffer added to mouse-smooth-scroll-internal and
         mouse-in-scroll-bar-internal
 4/21/03 merged current LW and MCL files
 1/15/02 changed com-mouse-define-region to default all args so that calling it
         from boxer code will no longer blow out.  Instead, it behaves as if
         the mouse were clicked in it's current position
 5/15/01 *smooth-scroll-pause-time* changed to 0.005 for smoother scrolling of more
         complicated rows (like with boxes)
 5/11/01 mouse-smooth-scroll-internal fixed to provide useful time for timed-body
         *smooth-scroll-pause-time* changed from .01 to .001
 2/13/01 merged current LW and MCL files
 4/11/00 calls to ENTER by mouse coms now check to see if we are entering a box
         from below and pass the arg to suppress entry triggers
10/27/98 com-mouse-limit-scroll-box uses last-page-top-row instead of
         last-inferior-row
10/26/98 refinements to mouse-in-scroll-bar-internal so that lowest scroll position
         will include a full box of text
10/19/98 explicitly setup mouse-screen-row and mouse-x before entering tracking loop
         for shift click clause in mouse-define-region
10/15/98 added initialization for row height array in mouse-in-scroll-bar-internal
10/09/98 elevator-row-string used to limit the length row # display
10/08/98 new-elevator-scrolled-row
 8/27/98 Added size reporting in the status line to com-mouse-resize-box
 8/18/98 Reduce blinkiness in com-mouse-define-region by recycling the tracking
         blinkers for use in the newly defined region
 6/24/98 fixed com-mouse-resize-box to handle minimum size redisplay bug
 5/14/98 fix mouse-smooth-scroll-internal bug which crashed when scrolled down
         from a newly created box
 5/14/98 started logging changes: source = boxer version 2.3alphaR

|#



#-(or lispworks mcl lispm) (in-package 'boxer :use '(lisp) :nicknames '(box))
#+(or lispworks mcl)       (in-package :boxer)


;;;; MOUSE-CLICKS

(defboxer-command com-mouse-collapse-box (window x y mouse-bp click-only?)
  "make the one step smaller"
  ;; Note that this is designed to be called in the Boxer process,
  ;; not in the Mouse Process -- This is important!!!
  window x y click-only?    ;  (declare (ignore window x y click-only?))
  ;; first, if there already is an existing region, flush it
  (reset-region)
  (let ((new-box (bp-box mouse-bp))
	(new-row (bp-row mouse-bp))
	(mouse-screen-box (bp-screen-box mouse-bp))
	(new-cha-no (bp-cha-no mouse-bp)))
    (when (and (not-null new-row)
	       (box? new-box))
      (send-exit-messages new-box mouse-screen-box)
      (move-point-1 new-row new-cha-no mouse-screen-box)
      (com-collapse-box)))
  eval::*novalue*)

(defboxer-command com-mouse-shrink-box (window x y mouse-bp click-only?)
  "make the box tiny"
  ;; Note that this is designed to be called in the Boxer process,
  ;; not in the Mouse Process -- This is important!!!
  window x y click-only? ; (declare (ignore window x y click-only?))
  ;; first, if there already is an existing region, flush it
  (reset-region)
  (let ((new-box (bp-box mouse-bp))
	(new-row (bp-row mouse-bp))
	(mouse-screen-box (bp-screen-box mouse-bp))
	(new-cha-no (bp-cha-no mouse-bp)))
    (when (and (not-null new-row)
	       (box? new-box))
      (send-exit-messages new-box mouse-screen-box)
      (move-point-1 new-row new-cha-no mouse-screen-box)
      (com-shrink-box)))
  eval::*novalue*)

(defboxer-command com-mouse-super-shrink-box (window x y mouse-bp click-only?)
  "make the box tiny"
  ;; Note that this is designed to be called in the Boxer process,
  ;; not in the Mouse Process -- This is important!!!
  window x y click-only? ; (declare (ignore window x y click-only?))
  ;; first, if there already is an existing region, flush it
  (reset-region)
  (let ((new-box (bp-box mouse-bp))
	(new-row (bp-row mouse-bp))
	(mouse-screen-box (bp-screen-box mouse-bp))
	(new-cha-no (bp-cha-no mouse-bp)))
    (when (and (not-null new-row)
	       (box? new-box))
      (unless (and (not (eq mouse-screen-box (outermost-screen-box)))
		   mouse-screen-box
		   (eq :supershrunk
		       (display-style
			(screen-obj-actual-obj mouse-screen-box))))
	(send-exit-messages new-box mouse-screen-box)
	(move-point-1 new-row new-cha-no mouse-screen-box)
	(com-super-shrink-box))))
  eval::*novalue*)

(defboxer-command com-mouse-expand-box (window x y mouse-bp click-only?)
  "make the box one step bigger"
  ;; Note that this is designed to be called in the Boxer process,
  ;; not in the Mouse Process -- This is important!!!
  window x y click-only? ;  (declare (ignore window x y click-only?))
  ;; first, if there already is an existing region, flush it
  (reset-region)
  (let ((new-box (bp-box mouse-bp))
	(old-box (point-box))
	(new-row (bp-row mouse-bp))
	(mouse-screen-box (bp-screen-box mouse-bp))
	(new-cha-no (bp-cha-no mouse-bp)))
    (when (and (not-null new-row) (box? new-box))
      (unless (eq old-box new-box)
	(send-exit-messages new-box mouse-screen-box)
	(enter new-box (not (superior? old-box new-box))))
      (move-point-1 new-row new-cha-no mouse-screen-box)
      (com-expand-box)))
  eval::*novalue*)

(defboxer-command com-mouse-set-outermost-box (window x y mouse-bp click-only?)
  "make the box full screen"
  ;; Note that this is designed to be called in the Boxer process,
  ;; not in the Mouse Process -- This is important!!!
  window x y click-only? ;  (declare (ignore window x y click-only?))
  ;; first, if there already is an existing region, flush it
  (reset-region)
  (let ((old-box (point-box))
	(new-box (bp-box mouse-bp))
	(new-row (bp-row mouse-bp))
	(new-cha-no (bp-cha-no mouse-bp)))
    (when (and (not-null new-row) (box? new-box))
      (unless (eq old-box new-box)
	(send-exit-messages new-box (bp-screen-box mouse-bp))
	(enter new-box (not (superior? old-box new-box))))
      (move-point-1 new-row new-cha-no (bp-screen-box mouse-bp))
      (if (graphics-box? new-box)
	  (com-expand-box)
	  (com-set-outermost-box))))
  eval::*novalue*)

(defboxer-command com-mouse-move-point (window x y mouse-bp click-only? &optional (box-proc nil))
  "Go there"
  ;; Note that this is designed to be called in the Boxer process,
  ;; not in the Mouse Process -- This is important!!!
  window x y click-only? ;  (declare (ignore window x y click-only?))
  ;; first, if there already is an existing region, flush it
  (reset-region)
  (let ((old-box (point-box))
	(new-box (bp-box mouse-bp))
	(new-row (bp-row mouse-bp))
	(mouse-screen-box (bp-screen-box mouse-bp))
	(new-cha-no (bp-cha-no mouse-bp)))
    (when (and (not-null new-row) (not-null new-cha-no) (not-null new-box))
      (unless (eq old-box new-box)
	(send-exit-messages new-box mouse-screen-box)
	(enter new-box (not (superior? old-box new-box))))
      (move-point-1 new-row new-cha-no mouse-screen-box))
    (when (and (not box-proc)
	       (not (name-row? new-row))
	       (shrunken? (screen-obj-actual-obj (screen-box-point-is-in))))
      (com-expand-box)))
  ;(repaint-cursor)
  eval::*novalue*)

(defboxer-command com-mouse-define-region (&optional (window *boxer-pane*)
                                                     (x (bw::boxer-pane-mouse-x))
                                                     (y (bw::boxer-pane-mouse-y))
                                                     (mouse-bp
                                                      (mouse-position-values x y))
                                                     (click-only? t)
                                                     (shift?
                                                      (bw::shift-key-pressed?)))
  "Define a region with the mouse"
  window ; (declare (ignore window))
  ;; first, if there already is an existing region, flush it
  (reset-region) ; might want to reposition instead when shift-clicking
  ;; then go to where the mouse is pointing
  (let ((old-box (point-box)) (new-box (bp-box mouse-bp)) (new-row (bp-row mouse-bp))
        (mouse-screen-box (bp-screen-box mouse-bp)) (new-cha-no (bp-cha-no mouse-bp))
        ;; should probably eventually make this a global var...
        (mouse-position (fill-doit-cursor-position-vector
                         (make-process-doit-cursor-position) mouse-bp)))
    (when (and (not shift?)
               ;; if the shift key is pressed, don't move the point...
               (not-null new-row) (not-null new-cha-no) (not-null new-box))
      (unless (eq old-box new-box)
        (send-exit-messages new-box mouse-screen-box t )
        (enter new-box (not (superior? old-box new-box))))
      ;; enter method needs to be called 1st because we may need to fill
      ;; a boxes contents before moving
      (cond ((or (null (superior-box new-row))
                 (not (superior? (superior-box new-row) *initial-box*)))
             ;; sometimes the destination can become munged as a result of
             ;; trigger action via send-exit-messages
             (restore-point-position mouse-position t))
            (t
             (move-point-1 new-row new-cha-no mouse-screen-box))))
    (when (and (not (name-row? new-row))
               (shrunken? (screen-obj-actual-obj (screen-box-point-is-in))))
      (com-expand-box)
      (repaint)))
  (when (or (null click-only?) shift?)
    ;; now go about dragging a region defined by *point* and the mouse-bp
    ;; unless the user is no longer holding the mouse button down
    ; (repaint-cursor)
    ;; now track the mouse
    (multiple-value-bind (original-screen-row original-x)
        (if shift?
            (let ((csr (current-screen-row (point-row))))
              (values csr (cha-no->x-coord csr (point-cha-no))))
          (mouse-position-screen-row-values x y))
      (let ((original-screen-box (screen-box original-screen-row)))
        ;; should this be (bp-screen-box mouse-bp) ?
        (multiple-value-bind (original-context-x original-context-y)
            ;; these are the absolute offsets from which the
            ;; ORIGINAL-SCREEN-BOX is displaced
            (xy-context original-screen-box)
          ;;(decf original-context-x (sheet-inside-left *boxer-pane*))
          ;;(decf original-context-y (sheet-inside-top *boxer-pane*))
          ;; variables used by the loop
          ;; current-screen-box is the lowest level screen box that is
          ;; common to the *point* and the mark
          ;; current-screen-row is the screen-row WITHIN that box that
          ;; the mouse is on.
          ;; (screen-obj-x-offset <>) + context-x = window x-coordinate
          (let ((current-screen-box original-screen-box)
                (osb (outermost-screen-box))
                (mouse-screen-row original-screen-row)
                (mark-screen-row original-screen-row)
                (mouse-x original-x) (mark-x original-x) (mark-screen-box nil)
                (context-x original-context-x)(context-y original-context-y))
            (when shift?
              (multiple-value-setq (mouse-screen-row mouse-x)
                  (mouse-position-screen-row-values x y)))
            (catch 'mouse-confusion
              (unwind-protect
                  ;; the inner mouse tracking loop...
                  (with-mouse-tracking ((raw-mouse-x x) (raw-mouse-y y))
                    ;; first check to make sure that the mouse is still
                    ;; inside of the current-screen-box
                    ;; if it isn't, then reset the current-screen-box
                    ;; and all the other variables associated with it, then
                    ;; turn off the highlighting
                    ;;
                    ;; Find the box by walking upward from the original
                    (catch 'mouse-tracking-body
                      ;; this DO loop updates current-screen-box,
                      ;; mark-screen-row and mark-screen-box
                      (do* ((new-box original-screen-box (superior-screen-box new-box))
                            ;; these are updated at the bottom of the loop
                            (new-context-x original-context-x
                                           (- new-context-x
                                              (screen-obj-x-offset new-box)
                                              (screen-obj-x-offset sup-row)))
                            (new-context-y original-context-y
                                           (- new-context-y
                                              (screen-obj-y-offset new-box)
                                              (screen-obj-y-offset sup-row)))
                            (new-mark-box nil)
                            (sup-row nil))
                           ((or (eq new-box osb) (eq (superior-screen-box new-box) osb))
                            ;; if we get this far, then we are either on the
                            ;; box or else use the outermost box
                            (cond
                             ((in-screen-box? new-box
                                              (- raw-mouse-x new-context-x)
                                              (- raw-mouse-y new-context-y))
                              (unless (eq new-box current-screen-box)
                                (setq current-screen-box new-box
                                      context-x new-context-x context-y new-context-y)
                                (setq mark-screen-box new-mark-box
                                      mark-screen-row
                                      (if (null new-mark-box)
                                          original-screen-row
                                        (screen-row new-mark-box)))))
                             ((eq new-box osb)
                              ;; If we are outside the outermost box, skip
                              ;; the rest of the action and continue looping
                              ;; until we are inside again
                              (throw 'mouse-tracking-body nil))
                             (t
                              (setq current-screen-box osb
                                    context-x 0 context-y 0
                                    mark-screen-box new-box
                                    mark-screen-row (screen-row new-box)))))
                        ;; DO innards
                        (when (in-screen-box? new-box
                                              (- raw-mouse-x new-context-x)
                                              (- raw-mouse-y new-context-y))
                          (unless (eq new-box current-screen-box)
                            (setq current-screen-box new-box
                                  context-x new-context-x context-y new-context-y)
                            ;; when the current-screen-box changes, the mark
                            ;; values must also change but we need to wait
                            ;; until the mouse-screen-row is calculated before
                            ;; we can properly determine the mark-x (because
                            ;; inferior boxes should ALWAYS be included)
                            (setq mark-screen-box new-mark-box
                                  mark-screen-row
                                  (if (null new-mark-box)
                                      original-screen-row
                                    (screen-row new-mark-box))))
                          (return))
                        ;; update the new-mark-box and context values now
                        (setq new-mark-box new-box
                              sup-row (screen-row new-box)))
                      ;; DO loop ends

                      ;; At this point, we know that current-screen-box,
                      ;; mark-screen-row and mark-screen-box are all valid
                      ;; we now want to update mark-x, mouse-screen-row and
                      ;; mouse-x.  this will depend upon the relative position
                      ;; of the mouse and the mark
                      (multiple-value-bind (new-screen-obj offset position near-row)
                          (screen-obj-at current-screen-box
                                         (- raw-mouse-x context-x )
                                         (- raw-mouse-y context-y ) nil)
                        (cond ((screen-row? new-screen-obj)
                               (setq mouse-screen-row new-screen-obj)
                               ;; compare relative positions of mouse and mark
                               ;; to generate correct mark-x and mouse-x
                               (cond ((eq new-screen-obj mark-screen-row)
                                      (cond ((null mark-screen-box)
                                             (setq mark-x original-x
                                                   mouse-x
                                                   (if (or (not (screen-box? position))
                                                           (< offset mark-x))
                                                       offset
                                                     (+ offset
                                                        (screen-obj-wid position)))))
                                            ((< (screen-obj-x-offset mark-screen-box)
                                                offset)
                                             (setq mark-x
                                                   (screen-obj-x-offset mark-screen-box)
                                                   mouse-x
                                                   (if (screen-box? position)
                                                       (+ offset
                                                          (screen-obj-wid position))
                                                     offset)))
                                            (t
                                             (setq mark-x
                                                   (+ (screen-obj-x-offset
                                                       mark-screen-box)
                                                      (screen-obj-wid mark-screen-box))
                                                   mouse-x offset))))
                                     ((< (screen-obj-y-offset mark-screen-row)
                                         (screen-obj-y-offset new-screen-obj))
                                      ;; mouse is behind the mark
                                      (setq mouse-x
                                            (if (screen-box? position)
                                                (+ offset (screen-obj-wid position))
                                              offset)
                                            mark-x
                                            (if (null mark-screen-box)
                                                original-x
                                              (screen-obj-x-offset mark-screen-box))))
                                     (t
                                      ;; mark must be behind the mouse
                                      (setq mouse-x offset
                                            mark-x
                                            (if (null mark-screen-box)
                                                original-x
                                              (+
                                               (screen-obj-x-offset mark-screen-box)
                                               (screen-obj-wid mark-screen-box)))))))
                              ((eq position :left)
                               (setq mouse-screen-row near-row mouse-x 0)
                               ;; mouse should be in front of the mark
                               (setq mark-x
                                     (if (null mark-screen-box)
                                         original-x
                                       (+ (screen-obj-x-offset mark-screen-box)
                                          (screen-obj-wid mark-screen-box)))))
                              ((eq position :right)
                               (setq mouse-screen-row near-row
                                     mouse-x (screen-obj-wid near-row))
                               ;; mouse must be after the mark
                               (setq mark-x
                                     (if (null mark-screen-box)
                                         original-x
                                       (screen-obj-x-offset mark-screen-box))))
                              ((eq position :top)
                               (setq mouse-screen-row (first-screen-row
                                                       current-screen-box)
                                     mouse-x 0)
                               ;; the mouse must be in front of the mark
                               (setq mark-x
                                     (if (null mark-screen-box)
                                         original-x
                                       (+
                                        (screen-obj-x-offset mark-screen-box)
                                        (screen-obj-wid mark-screen-box)))))
                              ((eq position :bottom)
                               (setq mouse-screen-row (last-screen-row
                                                       current-screen-box)
                                     mouse-x (screen-obj-wid mouse-screen-row))
                               ;; mouse must be after the mark
                               (setq mark-x
                                     (if (null mark-screen-box)
                                         original-x
                                       (screen-obj-x-offset mark-screen-box))))
                              (t
                               ;; we should be here....
                               (warn "Can't find mouse for ~A, ~D, ~A"
                                     new-screen-obj offset position)
                               (setq mouse-screen-row
                                     (first-screen-row current-screen-box)
                                     mouse-x 0
                                     mark-x (if (null mark-screen-box)
                                                original-x
                                              (+ (screen-obj-x-offset mark-screen-box)
                                                 (screen-obj-wid mark-screen-box)))))))
                      ;; Now mark-x, mouse-screen-row and mouse-x should be correct

                      ;; sanity check
                      (unless (and (eq current-screen-box (screen-box mouse-screen-row))
                                   (eq current-screen-box (screen-box mark-screen-row)))
                        (warn "Mouse (~A) and Mark (~A) are confused"
                              mouse-screen-row mark-screen-row)
                        (throw 'mouse-confusion nil))

                      ;; Now all the mark and mouse variables are valid and
                      ;; (maybe) repaint the screen, showing new region...
                      (let ((mark-row (screen-obj-actual-obj mark-screen-row))
                            (mouse-row (screen-obj-actual-obj mouse-screen-row))
                            (mark-cha-no (screen-offset->cha-no mark-screen-row mark-x))
                            (mouse-cha-no (screen-offset->cha-no mouse-screen-row
                                                                 mouse-x)))
                        (flet ((same-pos? (mouse-1st?)
                                 (let ((bp1 (if mouse-1st?
                                                (interval-start-bp
                                                 *region-being-defined*)
                                              (interval-stop-bp *region-being-defined*)))
                                       (bp2 (if mouse-1st?
                                                (interval-stop-bp *region-being-defined*)
                                              (interval-start-bp
                                               *region-being-defined*))))
                                   (and (eq mouse-row (bp-row bp1))
                                        (= mouse-cha-no (bp-cha-no bp1))
                                        (eq mark-row (bp-row bp2))
                                        (= mark-cha-no (bp-cha-no bp2))))))
                          (cond ((null *region-being-defined*)
                                 (let ((mark-bp (make-bp ':fixed))
                                       (mouse-bp (make-bp ':fixed)))
                                   (setf (bp-row mark-bp) mark-row
                                         (bp-row mouse-bp) mouse-row
                                         (bp-cha-no mark-bp) mark-cha-no
                                         (bp-cha-no mouse-bp) mouse-cha-no)
                                   (setq *region-being-defined*
                                         (if (or (row-> mark-row mouse-row)
                                                 (and (eq mark-row mouse-row)
                                                      (> mark-cha-no mouse-cha-no)))
                                             (make-editor-region mouse-bp mark-bp)
                                           (make-editor-region mark-bp mouse-bp))))
                                 (push *region-being-defined* *region-list*)
                                 (repaint))
                                ((or (row-> mark-row mouse-row)
                                     (and (eq mark-row mouse-row)
                                          (> mark-cha-no mouse-cha-no)))
                                 ;; mouse is in front of mark
                                 (cond ((same-pos? t)
                                        ;; mouse hasn't moved, so do nothing
                                        )
                                       (t (let ((bp1 (interval-start-bp
                                                      *region-being-defined*))
                                                (bp2 (interval-stop-bp
                                                      *region-being-defined*)))
                                            (setf (bp-row bp1) mouse-row
                                                  (bp-cha-no bp1) mouse-cha-no
                                                  (bp-row bp2) mark-row
                                                  (bp-cha-no bp2) mark-cha-no))
                                          (repaint))))
                                (t ; mark is in front of mouse...
                                 (cond ((same-pos? nil))
                                       (t (let ((bp1 (interval-start-bp
                                                      *region-being-defined*))
                                                (bp2 (interval-stop-bp
                                                      *region-being-defined*)))
                                            (setf (bp-row bp1) mark-row
                                                  (bp-cha-no bp1) mark-cha-no
                                                  (bp-row bp2) mouse-row
                                                  (bp-cha-no bp2) mouse-cha-no))
                                          (repaint)))))))))
                ;; END of the mouse tracking loop
                ;; unwind-protect forms...
                (let ((mark-cha-no (screen-offset->cha-no mark-screen-row mark-x))
                      (mouse-cha-no (screen-offset->cha-no mouse-screen-row mouse-x)))
                  (cond ((and (eq mark-screen-row mouse-screen-row)
                              (=& mark-cha-no mouse-cha-no))
                         ;; no region to define so make sure we clean up the blinkers
                         (unless (null *region-being-defined*)
                           (setq *region-list*
                                 (fast-delq *region-being-defined* *region-list*)
                                 *region-being-defined*
                                 nil)
                           ;(repaint)
                           ))
                        (t
                         ;; region is still there so...
                         (entering-region-mode)))))
              )			; Matches catch 'mouse-confusion
            eval::*novalue*))))))

#|  ; unused ?
(defun reconcile-region-blinker-list (region blinker-list)
  (let ((existing-blinkers (interval-blinker-list region)))
    (cond ((not (null existing-blinkers))
           (when *boxer-system-hacker*
             (error "Region, ~A, already has blinkers" region))
           (dolist (bl blinker-list) (remove-region-row-blinker bl)))
          (t
           ;; we can just set it because the region redisplay will
           ;; handle the rest-see update-row-blinker-list called by
           ;; interval-update-redisplay-all-rows (region.lisp)
           (setf (interval-blinker-list region) blinker-list)
           ;; we do have to hack the visibility flag because we know
           ;; that the blinkers are already visible
           (setf (interval-visibility region) t)))))
|#



#|
;;; Multi-purpose box size changer.
;;; Lets you get by with just one button for changing size.

;;; Normal boxes:
;;;If clicked on the left half of the box, make it full screen.
;;;If on the right half of a box, make the box smaller.
;;; Shrunken boxes:
;;;Make full screen.
;;; Full Screen boxes:
;;;If clicked on the left half, make the box shrunken.
;;;If on the right half, make it normal size.
(defboxer-command com-mouse-change-box-size (window x y mouse-bp click-only?)
  "change the size of the box according to where you mouse"
  window x y click-only? ;  (declare (ignore window x y click-only?))
  ;; first, if there already is an existing region, flush it
  (reset-region)
  (let ((new-box (bp-box mouse-bp))
	(new-row (bp-row mouse-bp))
	(mouse-screen-box (bp-screen-box mouse-bp))
	(new-cha-no (bp-cha-no mouse-bp)))
    (when (and (not (null new-row)) (box? new-box))
      (let ((actual-obj (screen-obj-actual-obj mouse-screen-box)))
	(cond ((eq mouse-screen-box (outermost-screen-box))
	       (multiple-value-bind (row cha-no screen-box rel-x rel-y)
		   (mouse-position-values x y)
		 (declare (ignore row cha-no screen-box rel-y))
		 (send-exit-messages new-box mouse-screen-box)
		 (move-point-1 new-row new-cha-no mouse-screen-box)
		 (if (< (* rel-x 2)
			(screen-object-width mouse-screen-box))
		     (com-collapse-box)
		     (com-shrink-box))))
	      ((shrunken? actual-obj)
	       (send-exit-messages
		new-box mouse-screen-box
		(eq (superior-box (point-box)) new-box))
	       (move-point-1 new-row new-cha-no mouse-screen-box)
	       ;; no send-exit-messages yet.
	       (com-mouse-set-outermost-box window x y mouse-bp click-only?))
	      (t
	       (multiple-value-bind (row cha-no screen-box rel-x rel-y)
		 (screen-obj-at-position x y)
		 row cha-no screen-box rel-y
		 (send-exit-messages new-box mouse-screen-box)
		 (move-point-1 new-row new-cha-no mouse-screen-box)
		 (cond ((< (* rel-x 2)
			   (screen-object-width mouse-screen-box))
			(enter new-box)
			(com-expand-box))
		       (t
			(com-collapse-box)))))))))
  eval::*novalue*)

|#

(defboxer-command com-mouse-doit-now (window x y mouse-bp click-only?)
  "Go there and doit"
  ;; first, if there already is an existing region, flush it
  (reset-region)
  (let* ((screen-box (bp-screen-box mouse-bp))
	 (actual-box (screen-obj-actual-obj screen-box)))
    (cond ((null actual-box))
          ((and (shrunken? actual-box)
                (not (eq screen-box (outermost-screen-box))))
           ;; might as well open it
           (com-mouse-set-outermost-box window x y mouse-bp click-only?))
          (t
           (com-mouse-move-point window x y mouse-bp click-only?)
           (com-doit-now)
           eval::*novalue*))))

;;;; functions for cut,copy and paste
;;; mouse dispatch function

;;; mouse dispatch function
;(defun com-mouse-left-do-it-all (window x y mouse-bp click-only?)
;  (if #+clx (bw::mouse-on-region-being-defined-p) #-clx nil
;(com-suck-region window x y mouse-bp click-only?)
;      (com-mouse-collapse-box  window x y mouse-bp click-only?)))
;(defun com-mouse-right-do-it-all (window x y mouse-bp click-only?)
;  (if #+clx (bw::mouse-on-region-being-defined-p) #-clx nil
;      (com-suck-copy-region window x y mouse-bp click-only?)
;      (com-mouse-expand-box window x y mouse-bp click-only?)))

;;;;; killing and yanking stuff with the mouse and regions

(defvar *suitcase-region* nil
"kill the current region and jam the crap into the suitcase.")

(defvar *old-region-location* nil)

(defun suck-region ()
  (setq *suitcase-region*
	(or *region-being-defined* (get-current-region)))
  (cond ((not (null *suitcase-region*))
	 (with-region-top-level-bps (*suitcase-region* :start-bp-name start
						       :stop-bp-name stop)
	   (setq *old-region-location* (copy-bp start)))
	 (kill-region *suitcase-region*))
	(t
	 ;; just in case...
	 (unless (null *suitcase-mode*) (cleanup-suitcase))
	 (boxer-editor-error "No region to kill."))))

;;;
#| ;; old, use modes now
(defun entering-suitcase-bindings ()
  (save-and-rebind-key (current-mouse-click-name #+mcl 0 #-mcl 1 0)
                       #'com-bring-back-region)
  (save-and-rebind-key (current-mouse-click-name #+mcl 0 #-mcl 1 0 :graphics)
                       #'com-bring-back-region)
  (save-and-rebind-key (current-mouse-click-name #+mcl 0 #-mcl 1 0 :sprite)
                       #'com-bring-back-region))

(defun exiting-suitcase-bindings ()
  (restore-saved-function (current-mouse-click-name #+mcl 0 #-mcl 1 0))
  (restore-saved-function (current-mouse-click-name #+mcl 0 #-mcl 1 0 :graphics))
  (restore-saved-function (current-mouse-click-name #+mcl 0 #-mcl 1 0 :sprite)))
|#

(defun entering-suitcase-bindings ()
  (add-mode (suitcase-mode)))

(defun exiting-suitcase-bindings ()
  (remove-mode (suitcase-mode)))

;;; suck the region, make a suitcase out of it. rebind mouse-middle
(defun com-suck-region (&rest arguments)
  (declare (ignore arguments))
  (suck-region)
  (set-mouse-cursor :suitcase)
  (boxer-editor-message "Click to Insert Cut Text")
  (setq *suitcase-mode* t)
  ;; rebind various mouse-middle functions
  (entering-suitcase-bindings)
  (reset-region nil)
  (RESET-EDITOR-NUMERIC-ARG)
  eval::*novalue*)

;;; mouse-copy, non-destructive
(defun com-suck-copy-region (&rest arguments)
  (declare (ignore arguments))
  (suck-copy-region)
  (set-mouse-cursor :suitcase)
  (boxer-editor-message "Click to Insert Copied Text")
  (setq *suitcase-mode* t)
  (entering-suitcase-bindings)
  (reset-region nil)
  (RESET-EDITOR-NUMERIC-ARG)
  eval::*novalue*)

;;; suck the region up into a suitcase, without destroying the text sucked
(defun suck-copy-region ()
    (setq *suitcase-region*
	  (or *region-being-defined* (get-current-region)))
    (cond (*suitcase-region* (setq *suitcase-region*
				   (copy-interval *suitcase-region*)))
	  (t
	   ;; just in case...
	   (unless (null *suitcase-mode*) (cleanup-suitcase))
	   (boxer-editor-error "No region to copy."))))

;; cleanup function, it may be called after yanking or by the Abort key
(defun cleanup-suitcase ()
  (unless (null *suitcase-mode*)
    (unless (null *old-region-location*)
      (move-to-bp *old-region-location*)
      (unless (null *suitcase-region*)
	(yank-region *point* *suitcase-region*)
      (setq *old-region-location* nil)))
    (unless (null *suitcase-region*) (deallocate-region *suitcase-region*))
    (setq *suitcase-region* nil)
    (reset-mouse-cursor)
    (setq *suitcase-mode* nil)
    (exiting-suitcase-bindings)))

;; yank back the suitcase

(defun com-bring-back-region (window x y mouse-bp click-only?)
  (com-mouse-move-point window x y mouse-bp click-only?)
  (cond ((not (null *suitcase-region*))
	 (yank-region  *point* *suitcase-region*)
	 ;; if successful, no need to reset...
	 (setq *old-region-location* nil)
	 (cleanup-suitcase))
	((not (null *suitcase-mode*))
	 (cleanup-suitcase)))
  (reset-editor-numeric-arg)
  (reset-region)
  eval::*novalue*)





;;;; Commands for Mouse border Areas....

(defvar *warn-about-disabled-commands* t)
(defvar *only-shrink-wrap-text-boxes* nil)

(defboxer-command com-mouse-resize-box (window x y mouse-bp click-only?)
  "Resize the box with the mouse.  Just clicking unfixes the box size"
  window x y  ;  (declare (ignore window x y))
  ;; first, if there already is an existing region, flush it
  (reset-region)
  (let* ((screen-box (bp-screen-box mouse-bp))
	 (actual-box (screen-obj-actual-obj screen-box))
	 (box-type (box-type screen-box)))
    (cond ((null actual-box))
          ((shrunken? actual-box)
           ;; might as well open it
           (com-mouse-expand-box window x y mouse-bp click-only?))
          ((not (null click-only?))
           ;; reset the scrolling to the top
           (set-scroll-to-actual-row screen-box nil)
	   (set-fixed-size actual-box nil nil))
          ((and *only-shrink-wrap-text-boxes* (null (graphics-sheet actual-box)))
           (when *warn-about-disabled-commands*
             (boxer-editor-warning
              "Resizing Text Boxes is disabled, see the Preferences menu")))
	  ((eq screen-box (outermost-screen-box))
           (boxer-editor-warning
            "Can't Resize the Outermost Box. Resize the Window instead."))
	  (t
           ;; mouse grab, interactive loop
           (multiple-value-bind (box-window-x box-window-y)
	       (xy-position screen-box)
	     (multiple-value-bind (left top right bottom)
	         (box-borders-widths box-type screen-box)
	       ;(drawing-on-window (*boxer-pane*)
               (let ((minimum-track-wid *minimum-box-wid*)
                     (minimum-track-hei *minimum-box-hei*)
                     (first-movement-flag nil))
                 ;; if the box to be resized has a name, the minimum values
                 ;; should be different
                 (unless (null (name screen-box))
                   (multiple-value-bind (n-min-x n-min-y n-max-x n-max-y)
                       (box-borders-name-tab-values box-type screen-box)
                     (declare (ignore n-min-x))
                     (setq minimum-track-wid (max& n-max-x minimum-track-wid)
                           minimum-track-hei (+ minimum-track-hei
                                                (- n-max-y n-min-y)))))
                 (multiple-value-bind (final-x final-y moved-p)
                     (with-mouse-tracking ((mouse-x x) (mouse-y y)
                                           :action :resize)
                       (let ((new-wid (max& minimum-track-wid
                                            (- mouse-x box-window-x)))
                             (new-hei (max& minimum-track-hei
                                            (- mouse-y box-window-y)))
                             (last-wid (screen-obj-wid screen-box))
                             (last-hei (screen-obj-hei screen-box)))
                         (cond ((and (null first-movement-flag)
                                     ;; nothing is happening yet
                                     (= mouse-x x) (= mouse-y y)))
                               ((and (= new-wid last-wid) (= new-hei last-hei))
                                ;; same place, so do nothing...
                                )
                               (t
                                (when (null first-movement-flag)
                                  (setq first-movement-flag t))
                                (status-line-size-report screen-box
                                                         new-wid new-hei)
                                (let ((*update-bitmap?* nil))
                                  ;; suppress allocation of multiple different
                                  ;; sized bitmaps inside of loop
                                  (set-fixed-size actual-box
                                                  (- new-wid left right)
                                                  (- new-hei top bottom)))
                                (repaint)
                                ))))
                   ;; finalize..
                   (cond ((null moved-p)
                          ;; the mouse hasn't moved so we unfix the box size
                          (if (and (graphics-screen-box?
                                    (bp-screen-box mouse-bp))
                                   (graphics-box? actual-box))
                              (modified actual-box)
                            (progn (set-scroll-to-actual-row screen-box nil)
                              (set-fixed-size actual-box nil nil))))
                         (t
                          ;; make sure the mouse ended up in
                          ;; a reasonable place
                          (set-fixed-size actual-box
                                          (- (max minimum-track-wid
                                                  (- final-x box-window-x))
                                             left right)
                                          (- (max minimum-track-hei
                                                  (- final-y box-window-y))
                                             top bottom))
                          (when (and (data-box? actual-box)
                                     (auto-fill? actual-box))
                            ;; don't fill doit boxes !!
                            (com-fill-box actual-box))
                          (modified actual-box))))))))))
  ;)
  eval::*novalue*)

(defun status-line-size-report (screen-box wid hei)
  (multiple-value-bind (lef top rig bot)
      (box-borders-widths (box-type screen-box) screen-box)
    (let ((reporting-wid (- wid lef rig))
          (reporting-hei (- hei top bot)))
      (status-line-display 'boxer-editor-error
                           (if (graphics-screen-box? screen-box)
                               (format nil "New Size will be: ~D x ~D"
                                       reporting-wid reporting-hei)
                               (multiple-value-bind (cwid chei)
                                   (current-font-values)
                                 (format nil "New Size will be: ~D x ~D"
                                         (round reporting-wid cwid)
                                         (floor (+ 2 reporting-hei) chei))))))))

(defmacro mouse-corner-tracking ((corner) hilite-fun screen-box)
  (let ((delta-x (gensym)) (delta-y (gensym))
        (box-window-x (gensym)) (box-window-y (gensym))
        (width (gensym)) (height (gensym)))
    (ecase corner
      (:top-left
       `(multiple-value-bind (,box-window-x ,box-window-y)
            (xy-position ,screen-box)
          (multiple-value-bind (,delta-x ,delta-y ,width ,height)
              (tl-corner-tracking-info ,screen-box)
            (track-mouse-area ,hilite-fun
                              :x (+ ,box-window-x ,delta-x)
                              :y (+ ,box-window-y ,delta-y)
                              :width ,width :height ,height))))
      (:top-right
       `(multiple-value-bind (,box-window-x ,box-window-y)
            (xy-position ,screen-box)
          (multiple-value-bind (,delta-x ,delta-y ,width ,height)
              (tr-corner-tracking-info ,screen-box)
            (track-mouse-area ,hilite-fun
                              :x (+ ,box-window-x ,delta-x)
                              :y (+ ,box-window-y ,delta-y)
                              :width ,width :height ,height))))
      (:bottom-left
       `(multiple-value-bind (,box-window-x ,box-window-y)
            (xy-position ,screen-box)
          (multiple-value-bind (,delta-x ,delta-y ,width ,height)
              (bl-corner-tracking-info ,screen-box)
            (track-mouse-area ,hilite-fun
                              :x (+ ,box-window-x ,delta-x)
                              :y (+ ,box-window-y ,delta-y)
                              :width ,width :height ,height))))
      (:bottom-right
       `(multiple-value-bind (,box-window-x ,box-window-y)
            (xy-position ,screen-box)
          (multiple-value-bind (,delta-x ,delta-y ,width ,height)
              (br-corner-tracking-info ,screen-box)
            (track-mouse-area ,hilite-fun
                              :x (+ ,box-window-x ,delta-x)
                              :y (+ ,box-window-y ,delta-y)
                              :width ,width :height ,height)))))))

(defboxer-command com-mouse-br-corner-collapse-box (window x y mouse-bp
							   click-only?)
  "make the box one size larger"
  window x y  ; (declare (ignore window x y))
  ;; first, if there already is an existing region, flush it
  (reset-region)
  (let ((screen-box (bp-screen-box mouse-bp)))
    (when (or click-only?
	      (mouse-corner-tracking (:bottom-right) #'shrink-corner-fun screen-box))
      (let ((new-box (bp-box mouse-bp))
	    (new-row (bp-row mouse-bp))
	    (new-cha-no (bp-cha-no mouse-bp)))
	(when (and (not-null new-row)
		   (box? new-box))
	  (unless (and (not (eq screen-box (outermost-screen-box)))
		       (and screen-box
			    (shrunken? (screen-obj-actual-obj screen-box))))
	    (send-exit-messages new-box screen-box)
	    (move-point-1 new-row new-cha-no screen-box)
	    (com-collapse-box))))))
  eval::*novalue*)

(defboxer-command com-mouse-tl-corner-collapse-box (window x y
							   mouse-bp click-only?)
  "make the box one size larger"
  window x y  ; (declare (ignore window x y))
  ;; first, if there already is an existing region, flush it
  (reset-region)
  (let ((screen-box (bp-screen-box mouse-bp)))
    (when (or click-only?
	      (mouse-corner-tracking (:top-left) #'shrink-corner-fun screen-box))
      (let ((new-box (bp-box mouse-bp))
	    (new-row (bp-row mouse-bp))
	    (new-cha-no (bp-cha-no mouse-bp)))
	(when (and (not-null new-row)
		   (box? new-box))
          (let* ((edbox (and screen-box (screen-obj-actual-obj screen-box)))
                 (ds (and edbox (display-style edbox))))
            (cond ((and (not (eq screen-box (outermost-screen-box)))
                        (eq ds :supershrunk)))
                  ((and (not (eq screen-box (outermost-screen-box)))
                        (eq ds :shrunk))
                   (com-collapse-box edbox))
                  (t
	           (send-exit-messages new-box screen-box)
	           (move-point-1 new-row new-cha-no screen-box)
	           (com-collapse-box))))))))
  eval::*novalue*)

(defboxer-command com-mouse-br-corner-shrink-box (window x y mouse-bp
							 click-only?)
  "make the box one size larger"
  window x y ;  (declare (ignore window x y))
  ;; first, if there already is an existing region, flush it
  (reset-region)
  (let ((screen-box (bp-screen-box mouse-bp)))
    (when (or click-only?
	      (mouse-corner-tracking (:bottom-right) #'shrink-corner-fun screen-box))
      (let ((new-box (bp-box mouse-bp))
	    (new-row (bp-row mouse-bp))
	    (new-cha-no (bp-cha-no mouse-bp)))
	(when (and (not-null new-row)
		   (box? new-box))
          (let* ((edbox (and screen-box (screen-obj-actual-obj screen-box)))
                 (ds (and edbox (display-style edbox))))
            (cond ((and (not (eq screen-box (outermost-screen-box)))
                        (eq ds :supershrunk)))
                  ((and (not (eq screen-box (outermost-screen-box)))
                        (eq ds :shrunk))
                   (com-shrink-box edbox))
                  (t
	           (send-exit-messages new-box screen-box)
	           (move-point-1 new-row new-cha-no screen-box)
	           (com-shrink-box))))))))
  eval::*novalue*)

(defboxer-command com-mouse-tl-corner-super-shrink-box (window x y mouse-bp
							       click-only?)
  "make the box one size larger"
  window x y ;  (declare (ignore window x y))
  ;; first, if there already is an existing region, flush it
  (reset-region)
  (let ((screen-box (bp-screen-box mouse-bp)))
    (when (or click-only?
	      (mouse-corner-tracking (:top-left) #'shrink-corner-fun screen-box))
      (let ((new-box (bp-box mouse-bp))
	    (new-row (bp-row mouse-bp))
	    (new-cha-no (bp-cha-no mouse-bp)))
	(when (and (not-null new-row)
		   (box? new-box))
	  (unless (and (not (eq screen-box (outermost-screen-box)))
		       screen-box
		       (eq :supershrunk
			   (display-style (screen-obj-actual-obj screen-box))))
	    (send-exit-messages new-box screen-box)
	    (move-point-1 new-row new-cha-no screen-box)
	    (com-super-shrink-box))))))
  eval::*novalue*)

(defboxer-command com-mouse-tr-corner-expand-box (window x y mouse-bp
							 click-only?)
  "make the box one size larger"
  window x y  ;  (declare (ignore window x y))
  ;; first, if there already is an existing region, flush it
  (reset-region)
  (let ((screen-box (bp-screen-box mouse-bp)))
    (when (or click-only?
	      (mouse-corner-tracking (:top-right) #'expand-corner-fun screen-box))
      (let ((old-box (point-box))
	    (new-box (bp-box mouse-bp))
	    (new-row (bp-row mouse-bp))
	    (mouse-screen-box (bp-screen-box mouse-bp))
	    (new-cha-no (bp-cha-no mouse-bp)))
	(when (and (not-null new-row) (box? new-box))
	  (unless (eq old-box new-box)
	    (send-exit-messages new-box mouse-screen-box)
	    (enter new-box (not (superior? old-box new-box))))
	  (move-point-1 new-row new-cha-no mouse-screen-box)
	  (com-expand-box)))))
  eval::*novalue*)

(defboxer-command com-mouse-br-corner-expand-box (window x y mouse-bp
							 click-only?)
  "make the box one size larger"
  window x y  ;  (declare (ignore window x y))
  ;; first, if there already is an existing region, flush it
  (reset-region)
  (let ((screen-box (bp-screen-box mouse-bp)))
    (when (or click-only?
	      (mouse-corner-tracking (:bottom-right) #'expand-corner-fun screen-box))
      (let ((old-box (point-box))
	    (new-box (bp-box mouse-bp))
	    (new-row (bp-row mouse-bp))
	    (mouse-screen-box (bp-screen-box mouse-bp))
	    (new-cha-no (bp-cha-no mouse-bp)))
	(when (and (not-null new-row) (box? new-box))
	  (unless (eq old-box new-box)
	    (send-exit-messages new-box mouse-screen-box)
	    (enter new-box (not (superior? old-box new-box))))
	  (move-point-1 new-row new-cha-no mouse-screen-box)
	  (com-expand-box)))))
  eval::*novalue*)

(defboxer-command com-mouse-br-corner-set-outermost-box (window x y mouse-bp
								click-only?)
  "make the box one size larger"
  window x y ;  (declare (ignore window x y))
  ;; first, if there already is an existing region, flush it
  (reset-region)
  (let ((screen-box (bp-screen-box mouse-bp)))
    (when (or click-only?
	      (mouse-corner-tracking (:bottom-right) #'expand-corner-fun screen-box))
      (let ((old-box (point-box))
	    (new-box (bp-box mouse-bp))
	    (new-row (bp-row mouse-bp))
	    (mouse-screen-box (bp-screen-box mouse-bp))
	    (new-cha-no (bp-cha-no mouse-bp)))
	(when (and (not-null new-row) (box? new-box))
	  (unless (eq old-box new-box)
	    (send-exit-messages new-box mouse-screen-box)
	    (enter new-box (not (superior? old-box new-box))))
	  (move-point-1 new-row new-cha-no mouse-screen-box)
	  (if (and (graphics-box? new-box)
		   (display-style-graphics-mode? (display-style-list new-box)))
	      (com-expand-box)
	      (com-set-outermost-box))))))
  eval::*novalue*)

(defboxer-command com-mouse-tr-corner-toggle-closet (window x y
							 mouse-bp click-only?)
  "Open the closet if it is closed and
   close the closet if it is open."
  window x y click-only?;  (declare (ignore window x y click-only?))
  ;; first, if there already is an existing region, flush it
  (reset-region)
  (let ((screen-box (bp-screen-box mouse-bp)))
    (cond ((closet-locked? screen-box)
           (when *warn-about-disabled-commands*
             (boxer-editor-warning "The Closet is currently locked")))
          ((or ;click-only?     ; try and suppress accidental closet clicks
            (mouse-corner-tracking (:top-right) #'toggle-corner-fun screen-box))
           (let ((old-box (point-box))
	         (new-box (bp-box mouse-bp))
	         (new-row (bp-row mouse-bp))
	         (mouse-screen-box (bp-screen-box mouse-bp))
	         (new-cha-no (bp-cha-no mouse-bp)))
	     (when (and (not-null new-row) (box? new-box))
	       (unless (eq old-box new-box)
	         (send-exit-messages new-box mouse-screen-box)
	         (enter new-box (not (superior? old-box new-box))))
	       (move-point-1 new-row new-cha-no mouse-screen-box)
	       (com-toggle-closets))))))
  eval::*novalue*)

(defboxer-command com-mouse-tl-corner-toggle-closet (window x y
							 mouse-bp click-only?)
  "Open the closet if it is closed and
   close the closet if it is open."
  window x y click-only?;  (declare (ignore window x y click-only?))
  ;; first, if there already is an existing region, flush it
  (reset-region)
  (let ((screen-box (bp-screen-box mouse-bp)))
    (cond ((closet-locked? screen-box)
           (when *warn-about-disabled-commands*
             (boxer-editor-warning "The Closet is currently locked")))
          ((or ;click-only?     ; try and suppress accidental closet clicks
            (mouse-corner-tracking (:top-left) #'toggle-corner-fun screen-box))
           (let ((old-box (point-box))
	         (new-box (bp-box mouse-bp))
	         (new-row (bp-row mouse-bp))
	         (mouse-screen-box (bp-screen-box mouse-bp))
	         (new-cha-no (bp-cha-no mouse-bp)))
	     (when (and (not-null new-row) (box? new-box))
	       (unless (eq old-box new-box)
	         (send-exit-messages new-box mouse-screen-box)
	         (enter new-box (not (superior? old-box new-box))))
	       (move-point-1 new-row new-cha-no mouse-screen-box)
	       (com-toggle-closets))))))
  eval::*novalue*)

(defvar *slow-graphics-toggle* t)

(defboxer-command com-mouse-bl-corner-toggle-box-view (window x y mouse-bp
							   click-only?)
  "Toggle the box view"
  window x y ;  (declare (ignore window x y))
  ;; first, if there already is an existing region, flush it
  (reset-region)
  (let* ((screen-box (bp-screen-box mouse-bp))
	 (box (screen-obj-actual-obj screen-box))
	 (screen-objs (screen-objs box))
	 (graphics-sheet (if (port-box? box)
			     (slot-value (ports box) 'graphics-info)
			     (slot-value box 'graphics-info)))
	 (display-style (display-style-list box)))
    (cond ((and (not (display-style-graphics-mode? display-style))
		(null graphics-sheet))
	   (boxer-editor-error "This box has no graphics"))
	  ((eq screen-box *outermost-screen-box*)
	   (boxer-editor-error "Can't toggle the view of the Outermost Box"))
	  ((if *slow-graphics-toggle*
               (and (let ((waited? (mouse-still-down-after-pause?
                                    *mouse-action-pause-time*)))
                      ;; if the user has clicked, but not waited long enough,
                      ;; maybe warn about how to win
                      (when (and (null waited?) *warn-about-disabled-commands*)
                        (boxer-editor-warning
                         "You have to hold the mouse down for ~A seconds to confirm"
                         *mouse-action-pause-time*))
                      waited?)
                    (mouse-corner-tracking (:bottom-left)
                                           #'toggle-corner-fun screen-box))
               (or click-only?
	           (mouse-corner-tracking (:bottom-left)
				          #'toggle-corner-fun screen-box)))
	    ;; modify the editor box
	   (if (display-style-graphics-mode? display-style)
	       (setf (display-style-graphics-mode? display-style) nil)
	       (setf (display-style-graphics-mode? display-style) t))
	   ;; then handle changes to the screen boxes
	   (dolist (sb screen-objs)
	     (toggle-type sb) (set-force-redisplay-infs? sb t))
	   (modified (box-screen-point-is-in)))))
  eval::*novalue*)

(defboxer-command com-mouse-border-name-box (window x y mouse-bp click-only?)
  "Bring up a name tab for the box"
  window x y   ;  (declare (ignore window x y))
  ;; first, if there already is an existing region, flush it
  (reset-region)
  (let ((screen-box (bp-screen-box mouse-bp)))
    (when (or click-only?
              (multiple-value-bind (box-window-x box-window-y)
                  (xy-position screen-box)
                (multiple-value-bind (delta-x delta-y width height)
                    (name-tab-tracking-info screen-box)
                  (track-mouse-area #'default-gui-fun
                                    :x (+ box-window-x delta-x)
                                    :y (+ box-window-y delta-y)
                                    :width width
                                    :height height))))
      (if (eq (bp-box mouse-bp) *initial-box*)
          (boxer-editor-error  "You cannot name the outermost box")
        (let ((box-to-name (screen-obj-actual-obj (bp-screen-box mouse-bp))))
          (unless (row? (slot-value box-to-name 'name))
            (set-name box-to-name (make-name-row '())))
          (send-exit-messages box-to-name screen-box)
          (move-point-1 (slot-value box-to-name 'name)
                        0 (bp-screen-box mouse-bp))
          (modified box-to-name)))))
  eval::*novalue*)

(defvar *enable-mouse-toggle-box-type?* t)

(defvar *mouse-action-pause-time* .6)

(defboxer-command com-mouse-border-toggle-type (window x y mouse-bp click-only?)
  "Toggle the type of the box"
  window x y ;  (declare (ignore window x y))
  ;; first, if there already is an existing region, flush it
  (reset-region)
  (let* ((screen-box (bp-screen-box mouse-bp))
	 (box-type (box-type screen-box)))
    (when (or (eq box-type 'data-box) (eq box-type 'doit-box))
      (if (not (null *enable-mouse-toggle-box-type?*))
          (when (multiple-value-bind (box-window-x box-window-y)
                    (xy-position screen-box)
                  (multiple-value-bind (delta-x delta-y width height)
                      (type-tab-tracking-info screen-box)
                    (and (not click-only?)
                         (let ((start-time (get-internal-real-time)))
                           (and (track-mouse-area #'toggle-corner-fun
                                                  :x (+ box-window-x delta-x)
                                                  :y (+ box-window-y delta-y)
                                                  :width width
                                                  :height height)
                                (> (- (get-internal-real-time) start-time)
                                   (* *mouse-action-pause-time*
                                      INTERNAL-TIME-UNITS-PER-SECOND)))))))
            (toggle-type (bp-box mouse-bp))
            (mark-file-box-dirty (bp-box mouse-bp)))
        (boxer-editor-error "Toggling of the box type with the mouse is disabled"))))
  eval::*novalue*)



;;; Note: These scroll bar commands can now be triggerd by action in the horizontal
;;; as well as the (usual) vertical scroll bar
;;; The com-mouse-?-scroll commands dispatch to more specific action depending upon what
;;; scroll area was initially moused

(defvar *only-scroll-current-box?* nil)
(defvar *smooth-scrolling?* nil)  ; for now...

(defboxer-command com-mouse-scroll-box (window x y mouse-bp click-only?)
  "Scroll or reposition the box"
  window x				;  (declare (ignore window x))
  ;; first, if there already is an existing region, flush it
  (reset-region)
  (let* ((screen-box (bp-screen-box mouse-bp))
         (edbox (screen-obj-actual-obj screen-box))
	 (box-type (box-type screen-box))
	 (fixed? (not (null (display-style-fixed-wid
                             (display-style-list edbox))))))
    (unless (and *only-scroll-current-box?* (neq screen-box (point-screen-box)))
      (unless fixed? ; fix the box size during scrolling
        (multiple-value-bind (current-wid current-hei)
  	    (screen-obj-size screen-box)
	  (multiple-value-bind (l-wid t-wid r-wid b-wid)
	      (with-font-map-bound (*boxer-pane*)
	        (box-borders-widths (box-type  (screen-box-point-is-in))
				    (screen-box-point-is-in)))
	    (set-fixed-size edbox
			    (- current-wid l-wid r-wid)
			    (- current-hei t-wid b-wid)))))
      (case (get-scroll-position x y screen-box box-type)
        (:v-up-button (if click-only?
                          (com-scroll-up-row screen-box)
                        (if *smooth-scrolling?*
                            (mouse-smooth-scroll-internal screen-box :up)
                          (mouse-line-scroll-internal screen-box :up))))
        (:v-down-button (if click-only?
                            (com-scroll-dn-row screen-box)
                          (if *smooth-scrolling?*
                              (mouse-smooth-scroll-internal screen-box :down)
                            (mouse-line-scroll-internal screen-box :down))))
        (:h-left-button (if click-only?
                            (h-scroll-screen-box screen-box *horizontal-click-scroll-quantum*)
                          (mouse-h-scroll screen-box :left)))
        (:h-right-button (if click-only?
                            (h-scroll-screen-box screen-box (- *horizontal-click-scroll-quantum*))
                           (mouse-h-scroll screen-box :right)))
        (:v-bar (mouse-in-v-scroll-bar-internal screen-box x y click-only?))
        (:h-bar (mouse-in-h-scroll-bar-internal screen-box x y)))
      ;; now restore the box, if we have fixed it before
      (unless fixed? (set-fixed-size edbox nil nil))))
  ;; if the cursor is in the box being scrolled (or some inferior), we
  ;; need to make sure that it gets moved to where it will become visible
  ;; The scroll-to-actual-row of the screen box is a good bet
  eval::*novalue*)

(defboxer-command com-mouse-page-scroll-box (window x y mouse-bp click-only?)
  "Scroll box by the page"
  window
  (reset-region)
  (let* ((screen-box (bp-screen-box mouse-bp))
	 (box-type (box-type screen-box))
	 (fixed? (not (null (display-style-fixed-wid
			     (display-style-list (screen-obj-actual-obj
						  screen-box)))))))
    (unless (and *only-scroll-current-box?* (neq screen-box (point-screen-box)))
      (unless fixed? ; fix the box size during scrolling
        (multiple-value-bind (wid hei)
	    (screen-obj-size screen-box)
	  (multiple-value-bind (left top right bottom)
              (box-borders-widths (box-type  (screen-box-point-is-in))
                                  (screen-box-point-is-in))
	    (set-fixed-size (screen-obj-actual-obj screen-box)
			    (- wid left right)
			    (- hei top bottom)))))
      (case (get-scroll-position x y screen-box box-type)
        (:v-up-button (if click-only?
                          (com-scroll-up-one-screen-box (list screen-box))
                        (mouse-page-scroll-internal :up screen-box)))
        (:v-down-button (if click-only?
                            (com-scroll-dn-one-screen-box (list screen-box))
                          (mouse-page-scroll-internal :down screen-box)))
        (:h-left-button (if click-only?
                            (h-scroll-screen-box screen-box (* 2 *horizontal-click-scroll-quantum*))
                          (mouse-h-scroll screen-box :left 2)))
        (:h-right-button (if click-only?
                             (h-scroll-screen-box screen-box (* 2 (- *horizontal-click-scroll-quantum*)))
                           (mouse-h-scroll screen-box :right 2)))
        (:v-bar (mouse-in-v-scroll-bar-internal screen-box x y click-only?))
        (:h-bar (mouse-in-h-scroll-bar-internal screen-box x y)))
      ;; now restore the box, if we have fixed it before
      (unless fixed? (set-fixed-size (screen-obj-actual-obj screen-box) nil nil))))
  ;; if the cursor is in the box being scrolled (or some inferior), we
  ;; need to make sure that it gets moved to where it will become visible
  ;; The scroll-to-actual-row of the screen box is a good bet
  eval::*novalue*)


(defboxer-command com-mouse-limit-scroll-box (window x y mouse-bp click-only?)
  "To the limit..."
  window
  (reset-region)
  (let* ((screen-box (bp-screen-box mouse-bp))
         (edbox (screen-obj-actual-obj screen-box))
	 (box-type (box-type screen-box)))
    (unless (and *only-scroll-current-box?* (neq screen-box (point-screen-box)))
      (multiple-value-bind (left top right bottom)
          (box-borders-widths box-type screen-box)
        (declare (ignore left right))
        (multiple-value-bind (wid hei)
            (screen-obj-size screen-box)
          (declare (ignore wid))
          (case (get-scroll-position x y screen-box box-type)
            (:v-up-button   (set-scroll-to-actual-row screen-box (first-inferior-row edbox)))
            (:v-down-button (set-scroll-to-actual-row screen-box
                                                      (last-page-top-row edbox (- hei top bottom))))
            (:h-left-button  (h-scroll-screen-box screen-box 100000)) ; any large number will do...
            (:h-right-button (h-scroll-screen-box screen-box -100000))
            (:v-bar (mouse-in-v-scroll-bar-internal screen-box x y click-only?))
            (:h-bar (mouse-in-h-scroll-bar-internal screen-box x y)))))))
  eval::*novalue*)

(defun last-page-top-row (box hei)
  (do ((row (last-inferior-row box) (previous-row row))
       (acc-height 0))
      ((or (null row) (>= acc-height hei))
       (if (null row) (first-inferior-row box) (next-row row)))
    (setq acc-height (+ acc-height (estimate-row-height row)))))

(defvar *initial-scroll-pause-time* .5
  "Seconds to pause after the 1st line scroll while holding the mouse")

(defvar *scroll-pause-time* 0.1
  "Seconds to pause between each line scroll while holding the mouse")

(defvar *smooth-scroll-pause-time* 0.005
  "Seconds to pause between each pixel scroll while holding the mouse")

(defun last-scrolling-row (editor-box)
  (previous-row (previous-row (last-inferior-row editor-box))))

(defun mouse-line-scroll-internal (screen-box direction)
  (if (eq direction :up)
      (com-scroll-up-row screen-box)
    (com-scroll-dn-row screen-box))
  ;; do one thing, show it, then pause...
  (capi::apply-in-pane-process *boxer-pane* #'repaint t)
  (simple-wait-with-timeout *initial-scroll-pause-time* #'(lambda () (zerop& (mouse-button-state))))
  ;; now loop
  (let* ((edbox (screen-obj-actual-obj screen-box))
         (1st-edrow (first-inferior-row edbox))
         (last-edrow (last-scrolling-row edbox)))
    (loop (when (or (zerop& (mouse-button-state))
                    (and (eq direction :up) (eq (scroll-to-actual-row screen-box) 1st-edrow))
                    (and (eq direction :down) (row-> (scroll-to-actual-row screen-box)
                                                     last-edrow)))
            ;; stop if the mouse is up or we hit one end or the other...
            (return))
          (if (eq direction :up)
              (com-scroll-up-row screen-box)
            (com-scroll-dn-row screen-box))
          (repaint)
          (simple-wait-with-timeout *scroll-pause-time*
                                    #'(lambda () (zerop& (mouse-button-state)))))))

;; pixel (as opposed to row) based scrolling
;; should we quantize on integral row on exit ??
;; no movement lines for now, presumably, disorientation should be less of a problem
;; no initial pause, start scrolling right away

(defvar *smooth-scroll-min-speed* 1)
(defvar *smooth-scroll-med-speed* 2)
(defvar *smooth-scroll-max-speed* 6) ; note must be less than (max-char-height)

(defun mouse-smooth-scroll-internal (screen-box direction)
  (drawing-on-window (*boxer-pane*)
    (queueing-screen-objs-deallocation
      (let* ((edbox (screen-obj-actual-obj screen-box))
             (1st-edrow (first-inferior-row edbox))
             (last-edrow (last-scrolling-row edbox))
             (slow-start-time (get-internal-real-time)))
        (multiple-value-bind (initial-mx initial-my) (mouse-window-coords)
          (declare (ignore initial-mx))
          (flet ((get-velocity ()
                   (let ((ydiff (- initial-my
                                    (multiple-value-bind (mx my) (mouse-window-coords)
                                      (declare (ignore mx)) my)))
                         (tdiff (- (get-internal-real-time) slow-start-time)))
                     (if (eq direction :up)
                         (cond ((or (> ydiff 10)
                                    (> tdiff (* 2 internal-time-units-per-second)))
                                *smooth-scroll-max-speed*)
                               ((or (> ydiff 5)
                                    (> tdiff internal-time-units-per-second))
                                *smooth-scroll-med-speed*)
                               (t *smooth-scroll-min-speed*))
                         (cond ((or (< ydiff -10)
                                    (> tdiff (* 2 internal-time-units-per-second)))
                                (- *smooth-scroll-max-speed*))
                               ((or (< ydiff -5)
                                    (> tdiff internal-time-units-per-second))
                                (- *smooth-scroll-med-speed*))
                               (t (- *smooth-scroll-min-speed*)))))))
            ;; everything needs to happen inside the screen-box
            (let ((bwid (screen-obj-wid screen-box))
                  (bhei (screen-obj-hei screen-box))
                  (body-time (round (* *smooth-scroll-pause-time*
                                       internal-time-units-per-second))))
              (multiple-value-bind (sb-x sb-y) (xy-position screen-box)
                (with-drawing-inside-region (sb-x sb-y bwid bhei)
                  ;; grab the initial y pos as a baseline for acceleration
                  (loop (when (or (zerop& (mouse-button-state))
                                  (and (eq direction :up)
                                       (or (eq (scroll-to-actual-row screen-box)
                                               1st-edrow)
                                           (null (scroll-to-actual-row screen-box)))
                                       (zerop (slot-value screen-box 'scroll-y-offset)))
                                  (and (eq direction :down)
                                       (row-> (or (scroll-to-actual-row screen-box)
                                                  (first-inferior-row edbox))
                                              last-edrow)))
                          (return))
                        (timed-body (body-time)
                          (let ((vel (get-velocity)))
                            (setq vel (pixel-scroll-screen-box screen-box vel))
                            (erase-scroll-buttons *last-scrolled-box* t)
                            (scroll-move-contents screen-box vel))
                          (draw-scroll-buttons screen-box t)
                          (force-graphics-output)))
                  ;; now maybe move the point so it is still visible after scrolling...
                  (let ((scroll-row (scroll-to-actual-row screen-box)))
                    (cond ((null scroll-row)
                           (move-point-1 (first-inferior-row
                                          (screen-obj-actual-obj screen-box))
                                         0 screen-box))
                          ((and (not (zerop (slot-value screen-box 'scroll-y-offset)))
                                (not (null (next-row scroll-row))))
                           (move-point-1 (next-row scroll-row) 0 screen-box))
                          (t (move-point-1 scroll-row 0 screen-box))))
                  ;; finally cover up our mistakes...
                  ;(set-force-redisplay-infs? screen-box) ; looks bad...
                  )))))))))

(defun mouse-page-scroll-internal (direction &rest screen-box-list)
  #+mcl (declare (dynamic-extent screen-box-list))
  #+lucid (declare (lcl::dynamic-extent screen-box-list))
  (if (eq direction :up)
      (com-scroll-up-one-screen-box screen-box-list)
      (com-scroll-dn-one-screen-box screen-box-list))
  (simple-wait-with-timeout *initial-scroll-pause-time*
			    #'(lambda () (zerop& (mouse-button-state))))
  (loop (when (zerop& (mouse-button-state)) (return))
	(if (eq direction :up)
	    (com-scroll-up-one-screen-box screen-box-list)
	    (com-scroll-dn-one-screen-box screen-box-list))
	#-opengl (redisplay)
        #+opengl (repaint)
	(simple-wait-with-timeout *scroll-pause-time*
				  #'(lambda ()
				      (zerop& (mouse-button-state))))))

(defvar *max-scroll-grid-increment* 15
  "Maximum number of pixels between each tick in the scroll bar grid")

(defvar *min-scroll-grid-increment* 4
  "Minimum number of pixels between each tick in the scroll bar grid")

(defvar *scroll-grid-width* 10)

(defun mouse-in-v-scroll-bar-internal (screen-box x y click-only?)
  (let ((start-row (or (scroll-to-actual-row screen-box)
                       (first-inferior-row (screen-obj-actual-obj screen-box)))))
    (multiple-value-bind (v-min-y v-max-y)
        (v-scroll-info screen-box)
      (multiple-value-bind (box-window-x box-window-y)
          (xy-position screen-box)
        (declare (ignore box-window-x))
        (let ((y-offset (+ box-window-y v-min-y))
              (v-working-height (- v-max-y v-min-y)))
          (if click-only?
              (set-v-scroll-row screen-box (min (/ (max 0 (- y y-offset))
                                                   v-working-height)
                                                1))
            (let* ((eb (screen-obj-actual-obj screen-box))
                   (no-of-rows (length-in-rows eb)))
              ;; bind these so we dont have to calculate them for each iteration
              ;; of the tracking loop
              (with-mouse-tracking ((mouse-x x) (mouse-y y))
                (declare (ignore mouse-x))
                (set-v-scroll-row screen-box
                                  (min (/ (max 0 (- mouse-y y-offset)) v-working-height) 1)
                                  eb
                                  no-of-rows)
                (repaint t)))))))
    (maybe-move-point-after-scrolling screen-box
                                      (if (row-> start-row
                                                 (or (scroll-to-actual-row screen-box)
                                                     (first-inferior-row (screen-obj-actual-obj
                                                                          screen-box))))
                                          :left
                                        :right))))

(defun set-v-scroll-row (screen-box fraction
                                    &optional (ed-box (screen-obj-actual-obj screen-box))
                                    (no-of-rows (length-in-rows ed-box)))
  (set-scroll-to-actual-row screen-box
                            (new-elevator-scrolled-row ed-box
                                                       (floor (* fraction (1-& no-of-rows))))))

#|
(defun mouse-in-scroll-bar-internal (screen-box x y click-only?
						box-window-x box-window-y
						wid hei left top right bottom)
  (declare (ignore left))
  (let* ((inside-hei (-& hei top bottom))
	 (available-shaft (-& inside-hei (*& *scroll-button-height* 2)))
	 (ed-box (screen-obj-actual-obj screen-box))
	 (norows (length-in-rows ed-box))
         (maxrow nil) ; a cache for the lowest desired row number
	 (scroll-row (scroll-to-actual-row screen-box))
	 (current-row-no (if (null scroll-row) 0
			     (row-row-no ed-box scroll-row)))
	 ;; mini scroll if there is more room than we want to use
	 (mini-scroll? (>& available-shaft
			   (* *max-scroll-grid-increment* norows)))
	 (shaft-height (if mini-scroll?
			   (* *max-scroll-grid-increment* norows)
			   available-shaft))
	 (shaft-y (if mini-scroll?
		      (+& top *scroll-button-height*
			  (floor (-& available-shaft
				     (* *max-scroll-grid-increment* norows))
				 2)
                          box-window-y)
		      (+& top *scroll-button-height* box-window-y)))
	 (elevator-y (+& (floor (* (/ current-row-no norows) shaft-height))
			 shaft-y))
	 (row-heights (make-array norows :initial-element nil))
         (x-offset (+& box-window-x (-& wid right))))
    (declare (simple-vector row-heights))
    (labels ((new-row-no (y)
               ;; make the lower limit include a full box of text
               ;; scrolling down to the last row makes it hard to use
               ;; the scrolling buttons on the resulting 1 row high box
               (let ((raw-row (round (* (/ (min& (max& 0 (-& y shaft-y)) shaft-height)
			                   shaft-height)
			                (1-& norows)))))
                 (cond ((null maxrow)
                        (let ((end (ending-row-no raw-row)))
                          (cond ((>=& end norows)
                                 ;; cache should be filled by call to ending-row-no
                                 (or maxrow raw-row))
                                (t raw-row))))
                       (t (min raw-row maxrow)))))
	     (get-row-height (row-no)
	       (let ((entry (svref& row-heights row-no)))
		 (cond ((null entry)
			(let* ((edrow (row-at-row-no ed-box row-no))
			       (scrow (car (screen-objs edrow)))
			       (row-height
				(if (and scrow
					 (not (screen-obj-y-got-clipped?
					       scrow)))
				    (screen-obj-hei scrow)
				    (estimate-row-height edrow))))
			  (setf (svref& row-heights row-no) row-height)
			  row-height))
		       (t entry))))
	     (draw-scroll-grid ()
               ;; erase the box border
               (erase-rectangle *scroll-grid-width* shaft-height
                                x-offset shaft-y)
               (let* ((single-incr (/ shaft-height norows))
                      (draw-singles? (< *min-scroll-grid-increment*
                                        single-incr)))
                 (when (< *min-scroll-grid-increment* (* 10 single-incr))
                   ;; don't draw grid lines at all if they would be too dense
                   (dotimes (i norows)
                     (let ((y-offset (+& (floor (* i single-incr)) shaft-y)))
                       (cond ((zerop& (mod i 10))
                              (draw-rectangle alu-seta
                                              (-& *scroll-grid-width* 2) 2
                                              x-offset y-offset))
                             ((zerop& (mod i 5))
                              (draw-rectangle alu-seta
                                              (-& *scroll-grid-width* 4) 2
                                              (+& x-offset 2) y-offset))
                             ((not (null draw-singles?))
                              (draw-rectangle alu-seta
                                              (-& *scroll-grid-width* 6) 1
                                              (+& x-offset 3)
                                              y-offset))))))))
	     (ending-row-no (starting-row)
	       (do* ((last-row (length row-heights)) (height 0)
		     (row starting-row (1+& row)))
		    ((>=& row last-row)
                     (setq maxrow starting-row) ;; fill the maxrow cache
                     row)
		 ;; need to do this AFTER last-row check
		 (setq height (+& height (get-row-height row)))
		 (when (>=& height inside-hei)
                   (return row))))
	     (draw-line-indicator ()
               (erase-rectangle *scroll-grid-width* 10 x-offset (-& shaft-y 10))
               ;; make the line counter 1-based
               (draw-string alu-seta *box-border-label-font-no*
                            (elevator-row-string (1+ current-row-no))
                            x-offset (-& shaft-y 10))
               (erase-rectangle *scroll-grid-width* 10
                                x-offset (+& shaft-y shaft-height))
               (draw-string alu-seta *box-border-label-font-no*
                            (elevator-row-string
                             (1+ (ending-row-no current-row-no)))
                            x-offset (+& shaft-y shaft-height)))
	     (draw-temp-elevator ()
	       (draw-rectangle alu-xor
                               (-& *scroll-grid-width* 2)
                               (+& *scroll-button-height* 2)
			       x-offset (1-& elevator-y)))
	     (erase-temp-elevator ()
	       (draw-rectangle alu-xor
                               (-& *scroll-grid-width* 2)
                               (+& *scroll-button-height* 2)
			       x-offset (1-& elevator-y))))
      (if click-only?
	  ;; don't have to do tracking, just figure out the row
	  (set-scroll-to-actual-row screen-box
				    (row-at-row-no ed-box (new-row-no y)))
	  ;; draw the grid and track
	  (drawing-on-window (*boxer-pane*)
            (with-clipping-inside (x-offset (- shaft-y 10)
                                            *scroll-grid-width* (+ 20 shaft-height))
              (draw-scroll-grid)
              ;; draw the original
              (draw-temp-elevator)
              (draw-line-indicator)
              (with-mouse-tracking ((mouse-x x) (mouse-y y))
                (let ((new (new-row-no mouse-y)))
                  (unless (=& new current-row-no)
                    (erase-temp-elevator)
                    (setq current-row-no new
                          elevator-y (+& (floor (* (/ current-row-no norows)
                                                   shaft-height))
                                         shaft-y))
                    (draw-line-indicator)
                    (draw-temp-elevator))))
              (erase-temp-elevator)
              (erase-rectangle *scroll-grid-width* shaft-height x-offset shaft-y))
            (force-graphics-output)
	    ;; actually make the change
	    (set-scroll-to-actual-row screen-box
                                      (new-elevator-scrolled-row ed-box
                                                                 current-row-no))
	    (set-force-redisplay-infs? screen-box))))))
|#

;; there is only room to display 2 digits of row #'s
(defun elevator-row-string (n)
  (format nil "~D" n))

;; we need to make sure that we don't leave just a single row for unfixed size
;; boxes because that makes it hard to use the scrolling machinery
;; should be smarter and estimate row heights so the lowest we go is still a boxful
;; of text
(defun new-elevator-scrolled-row (ed-box elevator-row-no)
  (let ((elevator-row (row-at-row-no ed-box elevator-row-no)))
    (cond ((and t ; (not (fixed-size? ed-box)) ;; note: Size is fixed temp, for ALL
                (eq elevator-row (last-inferior-row ed-box)))
           (or (previous-row elevator-row) elevator-row))
          (t elevator-row))))




(defboxer-command com-sprite-follow-mouse (window x y mouse-bp click-only?)
  "Grabs a sprite with the mouse and moves it around"
  window x y click-only? ; (declare (ignore window x y click-only?))
  (let ((box (bp-box mouse-bp)))
    (when (sprite-box? box)
      (drawing-on-window (*boxer-pane*)
        (let ((*current-sprite* box))
          (bu::follow-mouse)
          ;(follow-mouse-internal (sprite-box-associated-turtle box))
        ))))
  eval::*novalue*)



#|
(defvar *christmas-half-time* 0.5)
(defvar *number-of-christmas-blinks* 3)

(defboxer-command com-christmas-tree ()
  "Lights up the mouse sensitive parts of a box's border"
  ;; first, if there already is an existing region, flush it
  (reset-region)
  (drawing-on-window (*boxer-pane*)
  (let* ((screen-box (point-screen-box))
	 (box-type (box-type screen-box))
	 (resize-backing-store (allocate-backing-store
				*mouse-resize-corner-bitmap*))
	 (toggle-view-backing-store (allocate-backing-store
				     *mouse-toggle-view-bitmap*))
	 (name-stub-backing-store (allocate-backing-store
				   *mouse-name-tab-bitmap*))
	 (toggle-type-backing-store (allocate-backing-store
				     (if (eq box-type 'data-box)
					       *mouse-doit-toggle-bitmap*
					       *mouse-data-toggle-bitmap*))))
    (flet ((grab-back (store x y)
		      (bitblt-from-screen alu-seta
					  (offscreen-bitmap-width store)
					  (offscreen-bitmap-height store)
					  store x y 0 0))
	   (stamp-icon (icon x y)
		       (bitblt-to-screen alu-seta
					 (offscreen-bitmap-width icon)
					 (offscreen-bitmap-height icon)
					 icon 0 0 x y)))
      (multiple-value-bind (box-window-x box-window-y)
        (xy-position screen-box)
      (multiple-value-bind (left top right bottom)
	  (box-borders-widths box-type screen-box)
	(declare (ignore top))
	(multiple-value-bind (delta-x delta-y)
	    (box-borders-offsets box-type screen-box)
	  (let ((resize-x (-& (+& box-window-x (screen-obj-wid screen-box))
			      right))
		(resize-y (-& (+& box-window-y (screen-obj-hei screen-box))
			      bottom))
		(toggle-view-x (+& box-window-x delta-x))
		(toggle-view-y (+& box-window-y delta-y
				   (box-borders-cached-name-tab-height
				    (box-type screen-box) screen-box)))
		(toggle-type-x (+& box-window-x left))
		(toggle-type-y (-& (+& box-window-y (screen-obj-hei screen-box))
				   bottom)))
	    ;; first grab underlying areas
	    (grab-back resize-backing-store resize-x resize-y)
	    (grab-back toggle-view-backing-store toggle-view-x toggle-view-y)
	    (when (fast-memq box-type '(data-box 'doit-box))
	      (grab-back toggle-type-backing-store toggle-type-x toggle-type-y))
	    (with-multiple-execution
		(dotimes (i *number-of-christmas-blinks*)
		  (stamp-icon (let ((z (mod i 3)))
				(cond ((=& z 0) *mouse-resize-corner-bitmap*)
				      ((=& z 1) *mouse-expand-corner-bitmap*)
				      (t *mouse-shrink-corner-bitmap*)))
			      resize-x resize-y)
		  (stamp-icon *mouse-toggle-view-bitmap* toggle-view-x toggle-view-y)
		  (when (fast-memq box-type '(data-box 'doit-box))
		    (stamp-icon (if (eq box-type 'data-box)
				    *mouse-doit-toggle-bitmap*
				    *mouse-data-toggle-bitmap*)
				toggle-type-x toggle-type-y))
                  (force-graphics-output)
		  (sleep *christmas-half-time*)
		  (stamp-icon resize-backing-store resize-x resize-y)
		  (stamp-icon toggle-view-backing-store toggle-view-x toggle-view-y)
		  (when (fast-memq box-type '(data-box 'doit-box))
		    (stamp-icon toggle-type-backing-store
				toggle-type-x toggle-type-y))
                  (force-graphics-output)
		  (sleep *christmas-half-time*))))))))
    ;; deallocate the backing stores
    (deallocate-backing-store *mouse-resize-corner-bitmap*
			      resize-backing-store)
    (deallocate-backing-store *mouse-toggle-view-bitmap*
			      toggle-view-backing-store)
    (deallocate-backing-store *mouse-name-tab-bitmap*
			      name-stub-backing-store)
    (deallocate-backing-store (if (eq box-type 'data-box)
				  *mouse-doit-toggle-bitmap*
				  *mouse-data-toggle-bitmap*)
			      toggle-type-backing-store)))
  eval::*novalue*)
|#

