;; -*- Mode:LISP;Syntax: Common-Lisp; Package:BOXER;-*-
#|


 $Header$

 $Log$

    Boxer
    Copyright 1985-2020 Andrea A. diSessa and the Estate of Edward H. Lay

    Portions of this code may be copyright 1982-1985 Massachusetts Institute of Technology. Those portions may be
    used for any purpose, including commercial ones, providing that notice of MIT copyright is retained.

    Licensed under the 3-Clause BSD license. You may not use this file except in compliance with this license.

    https://opensource.org/licenses/BSD-3-Clause


                                         +-Data--+
                This file is part of the | BOXER | system
                                         +-------+



    Portable Popup Menus

Modification History (most recent at top)

 9/14/12 de-fixnum arithmetic: item-size, item-height, menu-size, draw-item, track-item,
                               menu-select, draw-doc, doc-{width,height}
                               popup-doc-{offset-coords,shrink,expand,view-flip,
                                          resize,toggle-type,graphics}
                               com-mouse-{tl,tr,bl,br,type-tag}-pop-up
 8/15/12 handle float return from string-wid in: draw-doc
 7/20/11 #+opengl menu-select added draw-menu for initial selection case
12/04/10 #-opengl draw-doc
 9/25/10 initial FULL OpenGL implementation
 6/15/05 added new popup docs, :bottom-right-off        = "Manual Sizing"
                               :top-left-initial-box    = "Box Menu"
                               :top-right-outermost-box = "Box Menu"
         used by popup-(un)doc-{shrink,expand,resize} to be more relevant to particular situations
 6/14/05 popup-doc-resize, popup clause moved to the end of function, it was causing
         a popup delay before any of the other mouse documentation could run
 6/12/05 for some reason, we had to add a window-system-dependent-set-origin
         call to popup-doc-resize even though we are in a drawing-on-window env
         and none of the other corner docs needs to
12/20/04 menu-select needed to have the window origin reset after the mouse loop
         for #+carbon-compat, also had to do the same for draw-doc
         changed *popup-mouse-documentation?* back to :unroll for  #+mcl now that it seems
         to be working again...
 8/25/04 update-{tr,tl}-menu smarter about disabling items in certain contexts
 6/17/04 added flush-port-buffers to {draw,erase}-doc
10/28/03 menu-select: removed flush-port-buffer that was inside with-mouse-tracking
         changed other flush-port-buffer to force-graphics-output
 9/02/03 added #+carbon-compat (flush-port-buffer) to menu-select
         changed sleep to snooze in selection confirm flashing loop
 4/21/03 merged current LW and MCL files
10/16/01 draw,erase-doc use *popup-doc-on?*
         popup-doc-xxx functions take extra popup-only? arg and wait for popup
 5/24/01 added *popup-mouse-documentation?* to control popup documentation
 4/25/01 popup-(un)doc-xxx helper functions done
 4/10/01 popup-doc done
 4/03/01 changed popup-doc methods to used shared backing store
 3/15/01 started popup-doc implementation
 2/17/01 merged current LW and MCL files
 5/29/00 #+lispworks in *tt-menu*
 4/12/00 calls to enter methods in hostspot coms now check for entry from below
         functions are: com-hotspot-shrink/expand/supershrink/full-screen-box
12/07/99 LWW: change font in menu-item class

5/11/98 changed draw-item to use new convention for draw-cha and ccl::*gray-color*
5/11/98 started logging changes: source = boxer version 2.3

|#

#-(or lispworks mcl lispm) (in-package 'boxer :use '(lisp) :nicknames '(box))
#+(or lispworks mcl)       (in-package :boxer)

(defclass menu-item
  ()
  ((title :initarg :title :initform "" :accessor menu-item-title)
   (action :initarg :action :initform nil)
   ;; font is an index into *boxer-pane*'s font map
   (font  :initarg :font
          :initform *default-font*)
   (enabled? :initform t)
   (checked? :initform nil))
  (:metaclass block-compile-class))

(defvar *menu-item-margin* 8)

(defclass popup-menu
  ()
  ((items :initarg :items :initform nil)
   (default-item-no :initarg :default-item-no :initform 0))
  (:metaclass block-compile-class))

;; "bubble help" used mostly for mouse documentation

(defclass popup-doc
  ()
  ((string :initarg :string :initform "" :accessor popup-doc-string))
  (:metaclass block-compile-class))



;;; menu item methods...
(defmethod set-menu-item-title ((menu menu-item) new-title)
  (setf (slot-value menu 'title) new-title))

(defmethod item-size ((item menu-item))
  (values
   (+ (* *menu-item-margin* 2)
       (string-wid (slot-value item 'font) (slot-value item 'title)))
   ;; leave a pixel above and below
   (+ (string-hei (slot-value item 'font)) 2)))

(defmethod item-height ((item menu-item))
  (+ (string-hei (slot-value item 'font)) 2))

(defvar *default-check-char* #+mcl (code-char 195) #-mcl #\o) ; mcl bullet is 165

(defmethod draw-item ((item menu-item) x y)
  (if (null (slot-value item 'enabled?))
      ;; grey it, if we can
      (with-pen-color (*gray*)
        ;; yuck why isn't gray bound somewhere
        (let ((check (slot-value item 'checked?)))
          (rebind-font-info ((slot-value item 'font))
            (cond ((null check))
                  ((characterp check)
                   (draw-cha alu-seta check (+ x 2) (+ y (cha-ascent))))
                  (t (draw-cha alu-seta *default-check-char*
                               (+ x 2)  (+ y (cha-ascent)))))))
        (draw-string alu-seta (slot-value item 'font) (slot-value item 'title)
                     (+ x *menu-item-margin*) (1+ y)))
      (progn
        (with-pen-color (*black*)
          (draw-string alu-seta (slot-value item 'font) (slot-value item 'title)
                       (+ x *menu-item-margin*) (1+ y))
          (let ((check (slot-value item 'checked?)))
            (rebind-font-info ((slot-value item 'font))
              (cond ((null check))
                    ((characterp check)
                     (draw-cha alu-seta check (+ x 2)  (+ y (cha-ascent))))
                    (t (draw-cha alu-seta *default-check-char*
                                 (+ x 2)  (+ y (cha-ascent))))))))))
  ;; return height used up
  (+ (string-hei (slot-value item 'font)) 2))

(defmethod set-menu-item-check-mark ((item menu-item) check-mark)
  (setf (slot-value item 'checked?) check-mark))

(defmethod menu-item-enable ((item menu-item))
  (setf (slot-value item 'enabled?) T))

(defmethod menu-item-disable ((item menu-item))
  (setf (slot-value item 'enabled?) nil))



;;; menu methods...
(defmethod menu-items ((menu popup-menu)) (slot-value menu 'items))

(defmethod find-menu-item ((menu popup-menu) title)
  (car (member title (slot-value menu 'items)
               :test #'(lambda (a b) (string-equal a (slot-value b 'title))))))

(defmethod menu-size ((menu popup-menu))
  (let ((wid 0) (hei 0))
    (dolist (item (slot-value menu 'items))
      (multiple-value-bind (iw ih)
          (item-size item)
        (setq wid (max wid iw)
              hei (+ hei ih))))
    ;; add 2 pixels to leave room for the shadowing
    ;; and another 1 for the border
    (values (+ wid 3) (+ hei 3))))

(defmethod draw-menu ((menu popup-menu) x y)
  (multiple-value-bind (mwid mhei) (menu-size menu)
    (erase-rectangle mwid mhei x y)
    (let ((acc-y (1+ y)))
      (dolist (item (slot-value menu 'items))
        (setq acc-y (+ acc-y (draw-item item x acc-y)))))
    ;; draw the top & left borders
    (draw-rectangle alu-seta (- mwid 2) 1 x y)
    (draw-rectangle alu-seta 1 (- mhei 2) x y)
    ;; and the bottom & right stubs
    (draw-rectangle alu-seta 4 1 x (+ y (- mhei 2)))
    (draw-rectangle alu-seta 1 4 (+ x (- mwid 2)) y)
    ;; draw the shadow rects
    (draw-rectangle alu-seta (- mwid 4) 2 (+ x 4) (+ y (- mhei 2)))
    (draw-rectangle alu-seta 2 (- mhei 4) (+ x (- mwid 2)) (+ y 4))))

;; the check for valid local coords should have already been made
(defmethod track-item ((menu popup-menu) local-y)
  (let ((acc-y 1))
    (dolist (item (slot-value menu 'items)
                  (let* ((last (car (last (slot-value menu 'items))))
                         (last-height (item-height last)))
                    (values last (- acc-y last-height) last-height)))
      (let ((item-height (item-height item)))
        (if (<= (- local-y acc-y) item-height) ; in the item
            (return (values item acc-y item-height))
            ;; otherwise, increment and continue
            (incf acc-y item-height))))))

(defvar *select-1st-item-on-popup* t)

;; this is the main method, it pops up at (x,y) then tracks the mouse
;; funcalling the selected menu-item-action
#+opengl
(defmethod menu-select ((menu popup-menu) x y)
  (multiple-value-bind (mwid mhei) (menu-size menu)
    (let* ((window-width (sheet-inside-width *boxer-pane*)); what about %clip-rig?
           (window-height (sheet-inside-height *boxer-pane*)) ; %clip-bot?
           (fit-x (- (+ x mwid) window-width))
           (fit-y (- (+ y mhei) window-height))
           ;; if either fit-? vars are positive, we will be off the screen
           (real-x (if (plusp fit-x) (- window-width mwid) x))
           (real-y (if (plusp fit-y) (- window-height mhei) y))
           ;; current-item is bound out here because we'll need it after the
           ;; tracking loop exits...
           (current-item nil))
      (unless (zerop (mouse-button-state))
        ;; make sure the mouse is still down
        ;; if the original x and y aren't good, warp the mouse to the new location
        ;; a more fine tuned way is to use fit-x and fit-y to shift the current
        ;; mouse pos by the amount the menu is shifted (later...)
        (drawing-on-window (*boxer-pane*)
          (when (or *select-1st-item-on-popup* (plusp fit-x) (plusp fit-y))
            (warp-pointer *boxer-pane* (+ real-x 5) (+ real-y 5)))
          ;; now draw the menu and loop
          (unwind-protect
            (progn
              ;; draw menu
              (draw-menu menu real-x real-y)
              (force-graphics-output)
              ;; loop
              (let ((current-y 0) (current-height 0))
                (with-mouse-tracking ((mouse-x real-x) (mouse-y real-y))
                  (let ((local-x (- mouse-x real-x)) (local-y (- mouse-y real-y)))
                    (if (and (< 0 local-x mwid) (< 0 local-y mhei))
                      ;; this means we are IN the popup
                      (multiple-value-bind (ti iy ih)
                                           (track-item menu local-y)
                        (cond ((and (null current-item)
                                    (not (slot-value ti 'enabled?)))
                               ;; no current, selected item is disabled...
                               )
                              ((null current-item)
                               ;; 1st time into the loop, set vars and then
                               (setq current-item ti current-y iy current-height ih)
                               ;; highlight
                               (draw-menu menu real-x real-y)
                               (with-pen-color (bw::*blinker-color*)
                                 (with-blending-on
                                   (draw-rectangle alu-seta (- mwid 3) ih
                                                   (1+ real-x) (+ real-y iy))))
                               (force-graphics-output))
                              ((eq ti current-item)) ; no change, do nothing
                              ((not (slot-value ti 'enabled?))
                               ;; redraw menu with nothing selected
                               (draw-menu menu real-x real-y)
                               (force-graphics-output)
                               (setq current-item nil))
                              (t ; must be a new item selected,
                               ;; redraw menu
                               (draw-menu menu real-x real-y)
                               ;; highlight selected item...
                               (with-pen-color (bw::*blinker-color*)
                                 (with-blending-on
                                   (draw-rectangle alu-seta (- mwid 3) ih
                                                   (1+ real-x) (+ real-y iy))))
                               (force-graphics-output)
                               ;; set vars
                               (setq current-item ti current-y iy current-height ih))))
                      ;; we are OUT of the popup
                      (cond ((null current-item)) ; nothing already selected
                            (t ; redraw menu with nothing selected
                             (draw-menu menu real-x real-y)
                             (force-graphics-output)
                             (setq current-item nil))))))
                ;; loop is done, either we are in and item or not
                ;; why do we have to do this ?
                #+carbon-compat
                (window-system-dependent-set-origin %origin-x-offset %origin-y-offset)
                (unless (null current-item)
                  ;; if we are in an item, flash and erase the highlighting
                  (dotimes (i 5)
                    (draw-menu menu real-x real-y)
                    (force-graphics-output) (snooze .05)
                    (with-pen-color (bw::*blinker-color*)
                      (with-blending-on
                        (draw-rectangle alu-seta (- mwid 3) current-height
                                        (1+ real-x) (+ real-y current-y))))
                    (force-graphics-output) (snooze .05)))))))
        ;; funcall the action (note we are OUTSIDE of the drawing-on-window
        (unless (null current-item)
          (let ((action (slot-value current-item 'action)))
            (unless (null action) (funcall action))))))))

#-opengl
(defmethod menu-select ((menu popup-menu) x y)
  (multiple-value-bind (mwid mhei) (menu-size menu)
    (let* ((window-width (sheet-inside-width *boxer-pane*)); what about %clip-rig?
           (window-height (sheet-inside-height *boxer-pane*)) ; %clip-bot?
           (fit-x (-& (+& x mwid) window-width))
           (fit-y (-& (+& y mhei) window-height))
           (backing (make-offscreen-bitmap *boxer-pane* mwid mhei))
           ;; if either fit-? vars are positive, we will be off the screen
           (real-x (if (plusp& fit-x) (-& window-width mwid) x))
           (real-y (if (plusp& fit-y) (-& window-height mhei) y))
           ;; current-item is bound out here because we'll need it after the
           ;; tracking loop exits...
           (current-item nil))
      (unless (zerop& (mouse-button-state))
        ;; make sure the mouse is still down
        ;; if the original x and y aren't good, warp the mouse to the new location
        ;; a more fine tuned way is to use fit-x and fit-y to shift the current
        ;; mouse pos by the amount the menu is shifted (later...)
        (drawing-on-window (*boxer-pane*)
          (when (or *select-1st-item-on-popup* (plusp& fit-x) (plusp& fit-y))
            (warp-pointer *boxer-pane* (+& real-x 5) (+& real-y 5)))
          ;; grab the area into the backing store
          (bitblt-from-screen alu-seta mwid mhei backing real-x real-y 0 0)
          ;; now draw the menu and loop
          (unwind-protect
            (progn
              ;; draw menu
              (draw-menu menu real-x real-y)
              ;; loop
              (let ((current-y 0) (current-height 0))
                (with-mouse-tracking ((mouse-x real-x) (mouse-y real-y))
                  (let ((local-x (-& mouse-x real-x)) (local-y (-& mouse-y real-y)))
                    (if (and (<& 0 local-x mwid) (<& 0 local-y mhei))
                      ;; this means we are IN the popup
                      (multiple-value-bind (ti iy ih)
                                           (track-item menu local-y)
                        (cond ((and (null current-item)
                                    (not (slot-value ti 'enabled?)))
                               ;; no current, selected item is disabled...
                               )
                              ((null current-item)
                               ;; 1st time into the loop, set vars and then
                               (setq current-item ti current-y iy current-height ih)
                               ;; highlight
                               (draw-rectangle alu-xor (-& mwid 3) ih
                                               (1+& real-x) (+& real-y iy)))
                              ((eq ti current-item)) ; no change, do nothing
                              ((not (slot-value ti 'enabled?))
                               ;; new item is disabled but we have to erase...
                               (draw-rectangle alu-xor (-& mwid 3) current-height
                                               (1+& real-x) (+& real-y current-y))
                               (setq current-item nil))
                              (t ; must be a new item selected,
                               (draw-rectangle alu-xor (-& mwid 3) ih
                                               (1+& real-x) (+& real-y iy))
                               ;; erase old,
                               (draw-rectangle alu-xor (-& mwid 3) current-height
                                               (1+& real-x) (+& real-y current-y))
                               ;; set vars
                               (setq current-item ti current-y iy current-height ih))))
                      ;; we are OUT of the popup
                      (cond ((null current-item)) ; nothing already selected
                            (t ; erase old item
                             (draw-rectangle alu-xor (-& mwid 3) current-height
                                             (1+& real-x) (+& real-y current-y))
                             (setq current-item nil))))))
                ;; loop is done, either we are in and item or not
                ;; why do we have to do this ?
                #+carbon-compat
                (window-system-dependent-set-origin %origin-x-offset %origin-y-offset)
                (unless (null current-item)
                  ;; if we are in an item, flash and erase the highlighting
                  (dotimes (i 5)
                    (draw-rectangle alu-xor (-& mwid 3) current-height
                                    (1+& real-x) (+& real-y current-y))
                    (force-graphics-output)
                    (snooze .05)))))
            (bitblt-to-screen alu-seta mwid mhei backing 0 0 real-x real-y)
            (free-offscreen-bitmap backing)))
        ;; funcall the action (note we are OUTSIDE of the drawing-on-window
        (unless (null current-item)
          (let ((action (slot-value current-item 'action)))
            (unless (null action) (funcall action))))))))




;;; popup doc methods

(defvar *popup-mouse-documentation?* #+lwwin :unroll #+mcl T #+opengl :unroll
  "Can be NIL (no documentation), :unroll or T")


;; use on non double-buffered window systems
#-opengl
(progn
;;; !!!! SHould use allocate-backing-store.....
;; called at the beginning and whenever the popup doc font is changed
(defun allocate-popup-backing ()
  (let ((wid 0)
        (padding (*& (+& *popup-doc-border-width* *popup-doc-padding*) 2)))
    (dolist (doc *popup-docs*)
      (setq wid (max wid (string-wid *popup-doc-font* (popup-doc-string doc)))))
    (let ((new-wid (+ padding wid))
          (new-hei (+ (string-hei *popup-doc-font*) padding)))
    (when (or (null *popup-doc-backing-store*)
              (not (= new-wid (offscreen-bitmap-width *popup-doc-backing-store*)))
              (not (= new-hei (offscreen-bitmap-height *popup-doc-backing-store*))))
      (unless (null *popup-doc-backing-store*)
        (free-offscreen-bitmap *popup-doc-backing-store*))
      (setq *popup-doc-backing-store*
            (make-offscreen-bitmap *boxer-pane* new-wid new-hei))))))

(def-redisplay-initialization (allocate-popup-backing))

)


;;  Practically speaking, this means def-redisplay-initialization
;; this also implies that we need to keep track of all popup docs because if we
;; change the font, we'll have to recalculate the string widths and possibly
;; reallocate new backing stores.

;; Since there can be only one popup-doc displyed at a time, we can use a shared
;; backing store.  It just has to be as large as the biggest doc.  We also need
;; to keep track of the biggest doc, in case the font is changed, then we
;; need to reallocate a larger doc based on the new font.

;(defmethod initialize-instance ((self popup-doc) &rest initargs) )

(defmethod draw-doc ((self popup-doc) x y)
  (let* ((swid (ceiling (string-wid *popup-doc-font* (slot-value self 'string))))
         (shei (string-hei *popup-doc-font*))
         (pad (+ *popup-doc-border-width* *popup-doc-padding*))
         (full-pad (* pad 2))
         (full-wid (+ swid full-pad))
         (full-hei (+ shei full-pad)))
    ;; crock,
    #+carbon-compat
    (window-system-dependent-set-origin %origin-x-offset %origin-y-offset)
    ;; first save
    #-opengl
    (bitblt-from-screen alu-seta full-wid full-hei *popup-doc-backing-store*
                        x y 0 0)
    ;; animation
    #-opengl
    (when (eq *popup-mouse-documentation?* :unroll)
      (with-pen-color (*popup-doc-color*)
        (do ((i 1 (+ i 3)))
            ((>= i shei))
          (draw-rectangle alu-seta (+& swid (*& *popup-doc-padding* 2)) i
                          (+& x *popup-doc-border-width*)
                          (+& y *popup-doc-border-width*))
          (force-graphics-output)
          (sleep .001))))
    ;; frame (left, top, right and bottom)
    (draw-rectangle alu-seta *popup-doc-border-width* full-hei x y)
    (draw-rectangle alu-seta full-wid *popup-doc-border-width* x y)
    (draw-rectangle alu-seta *popup-doc-border-width* full-hei
                    (- (+ x full-wid) *popup-doc-border-width*) y)
    (draw-rectangle alu-seta full-wid *popup-doc-border-width*
                    x (- (+ y full-hei) *popup-doc-border-width*))
    ;; background
    (with-pen-color (*popup-doc-color*)
      (draw-rectangle alu-seta
                      (+ swid (* *popup-doc-padding* 2))
                      (+ shei (* *popup-doc-padding* 2))
                      (+ x *popup-doc-border-width*)
                      (+ y *popup-doc-border-width*)))
    ;; doc string
    (draw-string alu-seta *popup-doc-font* (slot-value self 'string)
                 (+ x pad) (+ y pad)))
  #-opengl
  (force-graphics-output)
  ;; set the flag
  (setq *popup-doc-on?* t))

#+opengl
(defmethod erase-doc ((self popup-doc) x y)
  (declare (ignore x y))
  (repaint-window)
  (setq *popup-doc-on?* nil))

#-opengl
(defmethod erase-doc ((self popup-doc) x y)
  (let ((total-padding (*& (+& *popup-doc-border-width* *popup-doc-padding*) 2)))
    (bitblt-to-screen alu-seta
                      (+& (string-wid *popup-doc-font* (slot-value self 'string))
                          total-padding)
                      (+& (string-hei *popup-doc-font*) total-padding)
                      *popup-doc-backing-store* 0 0 x y)
    (force-graphics-output)
    (setq *popup-doc-on?* nil)))

(defmethod doc-width ((self popup-doc))
  (+ (ceiling (string-wid *popup-doc-font* (slot-value self 'string)))
      (* (+ *popup-doc-border-width* *popup-doc-padding*) 2)))

(defmethod doc-height ((self popup-doc))
  (+ (string-hei *popup-doc-font*)
      (* (+ *popup-doc-border-width* *popup-doc-padding*) 2)))

(define-popup-doc :top-left "Shrink")
(define-popup-doc :shrunken-top-left "Supershrink")

(define-popup-doc :top-right "Expand")
(define-popup-doc :fullscreen "Fullscreen")

(define-popup-doc :bottom-right "Resize")
(define-popup-doc :bottom-right-off "Manual Sizing")

(define-popup-doc :bottom-left-g "Graphics View")
(define-popup-doc :bottom-left-t "Text View")

(define-popup-doc :type "Toggle Type")

(define-popup-doc :name "Edit Name")

(define-popup-doc :name-handle "Name")

;; unused ?
(define-popup-doc :port-target-name "Target Name")

(define-popup-doc :port-target-type "Target Type")

(define-popup-doc :scroll-bar "Scroll")

;; for shrunken boxes?
(define-popup-doc :inside "Expand")

(define-popup-doc :graphics "Graphics Click")

(define-popup-doc :sprite "Sprite Click")

;; special cases
(define-popup-doc :top-left-initial-box "Box Menu")

(define-popup-doc :top-right-outermost-box "Box Menu")



;;; Popup doc Interface routines
;; these are what get called to do the actual documentation by mouse tracking
;; in the boxwin files
;; these functions must:
;; 1) decide if we should document (e.g. toggling not always available)
;; 2) if so, then:
;;       a) popup-doc (properly offset, i.e. not obscuring mouse or hotspot)
;;       b) highlighting hotspot if appropriate
;;       c) status-line doc
;; 3) undo doc

;; should be about doc size + mouse cursor size
(defparameter *popup-doc-edge-padding* 30)

;; for popup-doc offset, prefer below and to the right of the mouse
;; exceptions being if the mouse is near the right or bottom edges of the window
(defun popup-doc-offset-coords (doc x y)
  (multiple-value-bind (w h)
      (boxer::window-inside-size *boxer-pane*)
    (cond ((> (+ *popup-doc-edge-padding* y) h)
           (values (min x (- w (doc-width doc))) (- y (doc-height doc) 10)))
          (t (values (min x (- w (doc-width doc))) (+ y 26))))))

;;;; The main utilities (called from mousedoc.lisp via {un}document-mouse-dispatch)
;; the opengl undoc dispatch erases by redrawing the screen, no
;; need for specific versions

;; top left
(defun popup-doc-shrink (screen-box &optional supershrink? popup-only?)
  (let* ((box-type (box-type screen-box))
         (doc (get-popup-doc-for-area
               (cond ((eq (screen-obj-actual-obj screen-box) *initial-box*)
                      :top-left-initial-box)
                     ((not (null  supershrink?))
                      :shrunken-top-left)
                     (t :top-left))))
          #-opengl (hotspot-back (allocate-backing-store *mouse-shrink-corner-bitmap*))
          #-opengl (hotwid (offscreen-bitmap-width  *mouse-shrink-corner-bitmap*))
          #-opengl (hothei (offscreen-bitmap-height *mouse-shrink-corner-bitmap*)))
    (multiple-value-bind (x y)
        (xy-position screen-box)
      (multiple-value-bind (delta-x delta-y)
                           (box-borders-offsets box-type screen-box)
        (let ((corner-x (+ x delta-x))
              (corner-y (+ y delta-y
                            #+opengl
                            (box-top-y (name-string-or-null
                                        (screen-obj-actual-obj screen-box))
                                        0)
                            #-opengl
                            (box-borders-cached-name-tab-height box-type
                                                                screen-box))))
          ;; handle the highlighting immediatement
          #-opengl
          (unless popup-only?
            (bw::set-mouse-doc-status-backing hotspot-back)
            (bitblt-from-screen alu-seta hotwid hothei hotspot-back
                                corner-x corner-y 0 0)
            ;; draw the hotspot
            (bitblt-to-screen alu-seta hotwid hothei *mouse-shrink-corner-bitmap*
                              0 0 corner-x corner-y))
          #+opengl
          (unless popup-only?
            (bw::set-mouse-doc-status-xy corner-x corner-y))
          ;; then (possibly) the popup doc
          (unless (or (null *popup-mouse-documentation?*)
                      (bw::popup-doc-delay))
            (multiple-value-bind (doc-x doc-y)
                (popup-doc-offset-coords doc corner-x corner-y)
              #-opengl (draw-doc doc doc-x doc-y)
              #+opengl (bw::set-mouse-doc-popup-info doc doc-x doc-y))))))))

#-opengl
(defun popup-undoc-shrink (screen-box &optional supershrink?)
  (let ((box-type (box-type screen-box))
        (doc (get-popup-doc-for-area
              (cond ((eq (screen-obj-actual-obj screen-box) *initial-box*)
                      :top-left-initial-box)
                     ((not (null  supershrink?))
                      :shrunken-top-left)
                     (t :top-left))))
        (backing (bw::mouse-doc-status-backing))
        (hotwid (offscreen-bitmap-width  *mouse-shrink-corner-bitmap*))
        (hothei (offscreen-bitmap-height *mouse-shrink-corner-bitmap*)))
    (multiple-value-bind (x y)
        (xy-position screen-box)
      (multiple-value-bind (delta-x delta-y)
          (box-borders-offsets box-type screen-box)
        (let ((corner-x (+& x delta-x))
              (corner-y (+& y delta-y (box-borders-cached-name-tab-height
                                       box-type screen-box))))
          (unless (or (null *popup-mouse-documentation?*)
                      (null *popup-doc-on?*))
            (multiple-value-bind (doc-x doc-y)
                (popup-doc-offset-coords doc corner-x corner-y)
              (erase-doc doc doc-x doc-y)))
          ;; restore the hospot area
          (unless (null backing)
            (bitblt-to-screen alu-seta hotwid hothei backing 0 0 corner-x corner-y)
            (deallocate-backing-store *mouse-shrink-corner-bitmap* backing)))))))

;; top right

(defun popup-doc-expand (screen-box &optional fullscreen? popup-only?)
  (let ((box-type (box-type screen-box))
        (doc (get-popup-doc-for-area
              (cond ((eq screen-box (outermost-screen-box))
                     :top-right-outermost-box)
                    ((not (null fullscreen?))
                     :fullscreen)
                    (t :top-right))))
        #-opengl (hotspot-back (allocate-backing-store *mouse-expand-corner-bitmap*))
        #-opengl (hotwid (offscreen-bitmap-width  *mouse-expand-corner-bitmap*))
        #-opengl (hothei (offscreen-bitmap-height *mouse-expand-corner-bitmap*)))
    (multiple-value-bind (x y)
        (xy-position screen-box)
      (multiple-value-bind (delta-x delta-y)
          (box-borders-offsets box-type screen-box)
        (declare (ignore delta-x))
        (multiple-value-bind (lef top rig bot)
            (box-borders-widths box-type screen-box)
          (declare (ignore lef top bot))
          (let ((corner-x (+ x (screen-obj-wid screen-box) (- rig)))
                (corner-y (+ y delta-y
                              #+opengl
                              (box-top-y (name-string-or-null
                                          (screen-obj-actual-obj screen-box))
                                         0)
                              #-opengl
                              (box-borders-cached-name-tab-height
                               box-type screen-box))))
            #-opengl
            (unless popup-only?
              (bw::set-mouse-doc-status-backing hotspot-back)
              (bitblt-from-screen alu-seta hotwid hothei hotspot-back
                                  corner-x corner-y 0 0)
              ;; draw the hotspot
              (bitblt-to-screen alu-seta hotwid hothei *mouse-expand-corner-bitmap*
                                0 0 corner-x corner-y))
            #+opengl
            (unless popup-only?
              (bw::set-mouse-doc-status-xy corner-x corner-y))
            ;;
            (unless (or (null *popup-mouse-documentation?*)
                        (bw::popup-doc-delay))
              (multiple-value-bind (doc-x doc-y)
                  (popup-doc-offset-coords doc corner-x corner-y)
                #-opengl (draw-doc doc doc-x doc-y)
                #+opengl (bw::set-mouse-doc-popup-info doc doc-x doc-y)))))))))

#-opengl
(defun popup-undoc-expand (screen-box &optional fullscreen?)
  (let ((box-type (box-type screen-box))
        (doc (get-popup-doc-for-area
              (cond ((eq screen-box (outermost-screen-box))
                     :top-right-outermost-box)
                    ((not (null fullscreen?))
                     :fullscreen)
                    (t :top-right))))
        (hotspot-back (bw::mouse-doc-status-backing))
        (hotwid (offscreen-bitmap-width  *mouse-expand-corner-bitmap*))
        (hothei (offscreen-bitmap-height *mouse-expand-corner-bitmap*)))
    (multiple-value-bind (x y)
        (xy-position screen-box)
      (multiple-value-bind (delta-x delta-y)
          (box-borders-offsets box-type screen-box)
        (declare (ignore delta-x))
        (multiple-value-bind (lef top rig bot)
            (box-borders-widths box-type screen-box)
          (declare (ignore lef top bot))
          (let ((corner-x (+& x (screen-obj-wid screen-box) (-& rig)))
                (corner-y (+& y delta-y (box-borders-cached-name-tab-height
                                         box-type screen-box))))
            (unless (or (null *popup-mouse-documentation?*)
                        (null *popup-doc-on?*))
              (multiple-value-bind (doc-x doc-y)
                  (popup-doc-offset-coords doc corner-x corner-y)
                (erase-doc doc doc-x doc-y)))
            (unless (null hotspot-back)
              (bitblt-to-screen alu-seta hotwid hothei hotspot-back
                                0 0 corner-x corner-y)
              (deallocate-backing-store *mouse-expand-corner-bitmap*
                                        hotspot-back))))))))

;; bottom left

(defun popup-doc-view-flip (screen-box &optional to-graphics? popup-only?)
  (let ((box-type (box-type screen-box))
        (doc (get-popup-doc-for-area
              (if to-graphics? :bottom-left-g :bottom-left-t)))
        #-opengl(hotspot-back (allocate-backing-store *mouse-toggle-view-bitmap*))
        #-opengl(hotwid (offscreen-bitmap-width  *mouse-toggle-view-bitmap*))
        #-opengl(hothei (offscreen-bitmap-height *mouse-toggle-view-bitmap*)))
    (multiple-value-bind (x y)
        (xy-position screen-box)
      (multiple-value-bind (delta-x delta-y)
          (box-borders-offsets box-type screen-box)
        (declare (ignore delta-y))
        (multiple-value-bind (lef top rig bot)
            (box-borders-widths box-type screen-box)
          (declare (ignore lef top rig))
          (let ((corner-x (+ x delta-x))
                (corner-y (+ y (screen-obj-hei screen-box) (- bot))))
            #-opengl
            (unless popup-only?
              (bw::set-mouse-doc-status-backing hotspot-back)
              (bitblt-from-screen alu-seta hotwid hothei hotspot-back
                                  corner-x corner-y 0 0)
              ;; draw the hotspot
              (bitblt-to-screen alu-seta hotwid hothei *mouse-toggle-view-bitmap*
                                0 0 corner-x corner-y))
            #+opengl
            (unless popup-only?
              (bw::set-mouse-doc-status-xy corner-x corner-y))
            ;;
            (unless (or (null *popup-mouse-documentation?*)
                        (bw::popup-doc-delay))
              (multiple-value-bind (doc-x doc-y)
                  (popup-doc-offset-coords doc corner-x corner-y)
                #-opengl (draw-doc doc doc-x doc-y)
                #+opengl (bw::set-mouse-doc-popup-info doc doc-x doc-y)))
            ))))))

#-opengl
(defun popup-undoc-view-flip (screen-box &optional to-graphics?)
  (let ((box-type (box-type screen-box))
        (doc (get-popup-doc-for-area
              (if to-graphics? :bottom-left-g :bottom-left-t)))
        (hotspot-back (bw::mouse-doc-status-backing))
        (hotwid (offscreen-bitmap-width  *mouse-toggle-view-bitmap*))
        (hothei (offscreen-bitmap-height *mouse-toggle-view-bitmap*)))
    (multiple-value-bind (x y)
        (xy-position screen-box)
      (multiple-value-bind (delta-x delta-y)
          (box-borders-offsets box-type screen-box)
        (declare (ignore delta-y))
        (multiple-value-bind (lef top rig bot)
            (box-borders-widths box-type screen-box)
          (declare (ignore lef top rig))
          (let ((corner-x (+& x delta-x))
                (corner-y (+& y (screen-obj-hei screen-box) (-& bot))))
            (unless (or (null *popup-mouse-documentation?*)
                        (null *popup-doc-on?*))
              (multiple-value-bind (doc-x doc-y)
                  (popup-doc-offset-coords doc corner-x corner-y)
                (erase-doc doc doc-x doc-y)))
            (unless (null hotspot-back)
              (bitblt-to-screen alu-seta hotwid hothei hotspot-back
                                0 0 corner-x corner-y)
              (deallocate-backing-store *mouse-toggle-view-bitmap*
                                        hotspot-back))))))))

;; bottom right

(defun popup-doc-resize (screen-box popup-only? &optional is-off?)
  (let ((box-type (box-type screen-box))
        (doc (get-popup-doc-for-area (if is-off? :bottom-right-off :bottom-right)))
        #-opengl(hotspot-back (allocate-backing-store *mouse-resize-corner-bitmap*))
        #-opengl(hotwid (offscreen-bitmap-width  *mouse-resize-corner-bitmap*))
        #-opengl(hothei (offscreen-bitmap-height *mouse-resize-corner-bitmap*)))
    (multiple-value-bind (x y)
        (xy-position screen-box)
      (multiple-value-bind (lef top rig bot)
          (box-borders-widths box-type screen-box)
        (declare (ignore lef top))
        (let ((corner-x (+ x (screen-obj-wid screen-box) (- rig)))
              (corner-y (+ y (screen-obj-hei screen-box) (- bot))))
          #-opengl
          (unless popup-only?
            (bw::set-mouse-doc-status-backing hotspot-back)
            (bitblt-from-screen alu-seta hotwid hothei hotspot-back
                                corner-x corner-y 0 0)
            ;; draw the hotspot
            (bitblt-to-screen alu-seta hotwid hothei *mouse-resize-corner-bitmap*
                              0 0 corner-x corner-y))
          #+opengl
          (unless popup-only?
            (bw::set-mouse-doc-status-xy corner-x corner-y))
          (unless (or (null *popup-mouse-documentation?*)
                      (bw::popup-doc-delay))
            (multiple-value-bind (doc-x doc-y)
                (popup-doc-offset-coords doc corner-x corner-y)
              #-opengl (draw-doc doc doc-x doc-y)
              #+opengl (bw::set-mouse-doc-popup-info doc doc-x doc-y))))))))

#-opengl
(defun popup-undoc-resize (screen-box &optional is-off?)
  (let ((box-type (box-type screen-box))
        (doc (get-popup-doc-for-area (if is-off? :bottom-right-off :bottom-right)))
        (hotspot-back (bw::mouse-doc-status-backing))
        (hotwid (offscreen-bitmap-width  *mouse-resize-corner-bitmap*))
        (hothei (offscreen-bitmap-height *mouse-resize-corner-bitmap*)))
    (multiple-value-bind (x y)
        (xy-position screen-box)
      (multiple-value-bind (lef top rig bot)
          (box-borders-widths box-type screen-box)
        (declare (ignore lef top))
        (let ((corner-x (+& x (screen-obj-wid screen-box) (-& rig)))
              (corner-y (+& y (screen-obj-hei screen-box) (-& bot))))
          (unless (or (null *popup-mouse-documentation?*)
                      (null *popup-doc-on?*))
            (multiple-value-bind (doc-x doc-y)
                (popup-doc-offset-coords doc corner-x corner-y)
              (erase-doc doc doc-x doc-y)))
          (unless (null hotspot-back)
            (bitblt-to-screen alu-seta hotwid hothei hotspot-back
                              0 0 corner-x corner-y)
            (deallocate-backing-store *mouse-resize-corner-bitmap*
                                      hotspot-back)))))))

;; type tab
;; we don't light up the hotspot because it would look like the box has
;; already been toggled
(defun popup-doc-toggle-type (screen-box popup-only?)
  ;; no non popup doc but leave this here for future
  (declare (ignore popup-only?))
  (let ((box-type (box-type screen-box))
        (doc (get-popup-doc-for-area :type)))
    (multiple-value-bind (x y)
        (xy-position screen-box)
      (multiple-value-bind (lef top rig bot)
          (box-borders-widths box-type screen-box)
        (declare (ignore rig top))
        (let ((corner-x (+ x lef))
              (corner-y (+ y (screen-obj-hei screen-box) (- bot))))
          (unless (or (null *popup-mouse-documentation?*)
                      (bw::popup-doc-delay))
            (multiple-value-bind (doc-x doc-y)
                (popup-doc-offset-coords doc corner-x corner-y)
              #-opengl (draw-doc doc doc-x doc-y)
              #+opengl (bw::set-mouse-doc-popup-info doc doc-x doc-y))))))))

(defun popup-undoc-toggle-type (screen-box)
  (let ((box-type (box-type screen-box))
        (doc (get-popup-doc-for-area :type)))
    (multiple-value-bind (x y)
        (xy-position screen-box)
      (multiple-value-bind (lef top rig bot)
          (box-borders-widths box-type screen-box)
        (declare (ignore rig top))
        (let ((corner-x (+& x lef))
              (corner-y (+& y (screen-obj-hei screen-box) (-& bot))))
          (unless (or (null *popup-mouse-documentation?*)
                      (null *popup-doc-on?*))
            (multiple-value-bind (doc-x doc-y)
                (popup-doc-offset-coords doc corner-x corner-y)
              (erase-doc doc doc-x doc-y))))))))

(defun popup-doc-graphics (screen-box popup-only?)
  ;; no non popup doc but leave this here for future
  (declare (ignore popup-only?))
  (unless (or (null *popup-mouse-documentation?*)
              (bw::popup-doc-delay))
    (let ((doc (get-popup-doc-for-area :graphics)))
      (multiple-value-bind (x y)
          (xy-position screen-box)
        (multiple-value-bind (doc-x doc-y)
            (popup-doc-offset-coords doc (+ x 10) (+ y 10))
          #-opengl (draw-doc doc doc-x doc-y)
          #+opengl (bw::set-mouse-doc-popup-info doc doc-x doc-y))))))

(defun popup-undoc-graphics (screen-box)
  (unless (or (null *popup-mouse-documentation?*)
              (null *popup-doc-on?*))
    (let ((doc (get-popup-doc-for-area :graphics)))
      (multiple-value-bind (x y)
          (xy-position screen-box)
        (multiple-value-bind (doc-x doc-y)
            (popup-doc-offset-coords doc (+ x 10) (+ y 10))
          (erase-doc doc doc-x doc-y))))))




;;; Hotspots
(defvar *global-hotspot-control?* t)

;; bound by popup menu tracker for the benefit of the action COMs
(defvar *hotspot-mouse-box* nil)
(defvar *hotspot-mouse-screen-box* nil)

;; flags for global control
(defvar *top-left-hotspots-on?*     t)
(defvar *top-right-hotspots-on?*    t)
(defvar *bottom-left-hotspots-on?*  t)
(defvar *bottom-right-hotspots-on?* t)

(defboxer-command com-mouse-toggle-tl-hotspot (&optional (box *hotspot-mouse-box*))
  "Enables or Disables the top left Hotspot"
  (if *global-hotspot-control?*
      (setq *top-left-hotspots-on?* (not *top-left-hotspots-on?*))
      (set-top-left-hotspot-active? box (not (top-left-hotspot-active? box))))
  eval::*novalue*)

(defboxer-command com-mouse-toggle-tr-hotspot (&optional (box *hotspot-mouse-box*))
  "Enables or Disables the top right Hotspot"
  (if *global-hotspot-control?*
      (setq *top-right-hotspots-on?* (not *top-right-hotspots-on?*))
      (set-top-right-hotspot-active? box (not (top-right-hotspot-active? box))))
  eval::*novalue*)

(defboxer-command com-mouse-toggle-bl-hotspot (&optional (box *hotspot-mouse-box*))
  "Enables or Disables the bottom left Hotspot"
  (if *global-hotspot-control?*
      (setq *bottom-left-hotspots-on?* (not *bottom-left-hotspots-on?*))
      (set-bottom-left-hotspot-active? box (not (bottom-left-hotspot-active? box))))
  eval::*novalue*)

;; br hotspot ignores global flag
(defboxer-command com-mouse-toggle-br-hotspot (&optional (box *hotspot-mouse-box*))
  "Enables or Disables the Bottom Right Hotspot"
  (set-bottom-right-hotspot-active? box (not (bottom-right-hotspot-active? box)))
  eval::*novalue*)

;; shrink, expand and toggle closet
;; these are different from the vanilla mouse versions because the point is
;; not guaranteed to be in the box (although it may be, so we may need to
;; exit some boxes).
(defboxer-command com-hotspot-shrink-box (&optional (box *hotspot-mouse-box*)
                                                    (screen-box
                                                     *hotspot-mouse-screen-box*))
  "Shrink the box using the shrink hotspot"
  (let ((old-box (point-box)))
    (unless (eq old-box box)
      (send-exit-messages box screen-box)
      (enter box (not (superior? old-box box)))
      (move-point (box-first-bp-values box))
      (set-point-screen-box screen-box))
    (com-shrink-box box)))

(defboxer-command com-hotspot-supershrink-box (&optional (box *hotspot-mouse-box*)
                                                         (screen-box
                                                          *hotspot-mouse-screen-box*))
  "Supershrink the box using the shrink hotspot"
  (let ((old-box (point-box)))
    (unless (eq old-box box)
      (send-exit-messages box screen-box)
      (enter box (not (superior? old-box box)))
      (move-point (box-first-bp-values box))
      (set-point-screen-box screen-box))
    (com-super-shrink-box box)))

(defboxer-command com-hotspot-expand-box (&optional (box *hotspot-mouse-box*)
                                                    (screen-box
                                                     *hotspot-mouse-screen-box*))
  "Expand the Box using the Expand hotspot"
  (let ((old-box (point-box)))
    (unless (eq old-box box)
      (send-exit-messages box screen-box)
      (enter box (not (superior? old-box box)))
      (move-point (box-first-bp-values box))
      (set-point-screen-box screen-box))
    (com-expand-box)))

(defboxer-command com-hotspot-full-screen-box (&optional (box *hotspot-mouse-box*)
                                                         (screen-box
                                                          *hotspot-mouse-screen-box*))
  "Expand the Box to Full Screen via the Expand hotspot"
  (let ((old-box (point-box)))
    (unless (eq old-box box)
      (send-exit-messages box screen-box)
      (enter box (not (superior? old-box box)))
      (move-point (box-first-bp-values box))
      (set-point-screen-box screen-box))
    (if (and (graphics-box? box)
             (display-style-graphics-mode? (display-style-list box)))
        (com-expand-box)
        (com-set-outermost-box))))

(defboxer-command com-hotspot-toggle-closet (&optional (box *hotspot-mouse-box*)
                                                       (screen-box
                                                        *hotspot-mouse-screen-box*))
  "Open/Close the closet from a hotspot"
  (com-toggle-closets box screen-box))

(defboxer-command com-hotspot-toggle-graphics (&optional (box *hotspot-mouse-box*))
  "Flip from/to graphics presentation via the bottom left hotspot"
  (com-toggle-box-view box))




(defvar *tl-popup* (make-instance 'popup-menu
                                  :items (list (make-instance 'menu-item
                                    :title "Shrink"
                                    :action 'com-hotspot-shrink-box)
                                  (make-instance 'menu-item
                                    :title "Supershrink"
                                    :action 'com-hotspot-supershrink-box)
                                  (make-instance 'menu-item
                                    :title "Open Closet"
                                    :action 'com-hotspot-toggle-closet)
                                  (make-instance 'menu-item
                                    :title "Disable"
                                    :action 'com-mouse-toggle-tl-hotspot))))

;; synchronize the popup with the box
(defun update-tl-menu (box)
  (let ((shrink-item      (car    (menu-items *tl-popup*)))
        (supershrink-item (cadr   (menu-items *tl-popup*)))
        (closet-item      (caddr  (menu-items *tl-popup*)))
        (disable-item     (cadddr (menu-items *tl-popup*))))
    ;; adjust the menu for enable/disable info
    (cond ((or (and *global-hotspot-control?* *top-left-hotspots-on?*)
               (and (not *global-hotspot-control?*)
                    (top-left-hotspot-active? box)))
           ;; everything should be on...
           (cond ((eq box *initial-box*) (menu-item-disable shrink-item))
                 (t (menu-item-enable shrink-item)))
           (menu-item-enable closet-item)
           (cond ((eq box *initial-box*) (menu-item-disable supershrink-item))
                 (t (menu-item-enable supershrink-item)))
           (set-menu-item-title disable-item "Disable clicking"))
          (t ;; menu is disabled
           (menu-item-disable shrink-item)
           (menu-item-disable closet-item)
           (menu-item-disable supershrink-item)
           (set-menu-item-title disable-item "Enable clicking")))
    ;; adjust for current closet status
    (let ((closet-row (slot-value box 'closets)))
      (if (or (null closet-row) (null (row-row-no box closet-row)))
          ;; either there's no closet or it's currently closed...
          (set-menu-item-title closet-item "Open Closet")
          (set-menu-item-title closet-item "Close Closet")))))

(defun top-left-hotspot-on? (edbox)
  (or (and *global-hotspot-control?* *top-left-hotspots-on?*)
      (and (not *global-hotspot-control?*)
           (top-left-hotspot-active? edbox))))

(defboxer-command com-mouse-tl-pop-up (window x y mouse-bp click-only?)
  "Pop up a box attribute menu"
  window x y ;  (declare (ignore window x y))
  ;; first, if there already is an existing region, flush it
  (reset-region) (reset-editor-numeric-arg)
  (let* ((screen-box (bp-screen-box mouse-bp))
         (box-type (box-type screen-box))
         (edbox (screen-obj-actual-obj screen-box))
         ;; the coms in the pop up rely on there variables
         (*hotspot-mouse-box* edbox)
         (*hotspot-mouse-screen-box* screen-box))
    (if (and (not click-only?)
             (mouse-still-down-after-pause? 0)) ; maybe *mouse-action-pause-time* ?
        (multiple-value-bind (left top)
            (box-borders-widths box-type screen-box)
          ;; will probably have to fudge this for type tags near the edges of
          ;; the screen-especially the bottom and right edges
          (multiple-value-bind (abs-x abs-y) (xy-position screen-box)
            (update-tl-menu edbox)
            (menu-select *tl-popup* (+ abs-x left) (+ abs-y top))))
        ;; for simple clicks we do the action (unless it is disabled)
        (when (top-left-hotspot-on? edbox) (com-hotspot-shrink-box edbox))))
  eval::*novalue*)

(defvar *tr-popup* (make-instance 'popup-menu
                     :items (list (make-instance 'menu-item
                                    :title "Expand"
                                    :action 'com-hotspot-expand-box)
                                  (make-instance 'menu-item
                                    :title "Full Screen"
                                    :action 'com-hotspot-full-screen-box)
                                  (make-instance 'menu-item
                                    :title "Open Closet"
                                    :action 'com-hotspot-toggle-closet)
                                  (make-instance 'menu-item
                                    :title "Disable"
                                    :action 'com-mouse-toggle-tr-hotspot))))

;; synchronize the popup with the box
(defun update-tr-menu (box)
  (let ((expand-item      (car    (menu-items *tr-popup*)))
        (fullscreen-item  (cadr   (menu-items *tr-popup*)))
        (closet-item      (caddr  (menu-items *tr-popup*)))
        (disable-item     (cadddr (menu-items *tr-popup*))))
    ;; adjust the menu for enable/disable info
    (cond ((or (and *global-hotspot-control?* *top-right-hotspots-on?*)
               (and (not *global-hotspot-control?*)
                    (top-right-hotspot-active? box)))
           ;; everything should be on...
           (cond ((or (eq box (outermost-box))
                      (and (graphics-box? box)
                           (display-style-graphics-mode?
                            (display-style-list box))))
                  (menu-item-disable expand-item))
                 (t (menu-item-enable expand-item)))
           (menu-item-enable closet-item)
           (cond ((or (eq box (outermost-box))
                      (and (graphics-box? box)
                           (display-style-graphics-mode?
                            (display-style-list box))))
                  (menu-item-disable fullscreen-item))
                 (t (menu-item-enable fullscreen-item)))
           (set-menu-item-title disable-item "Disable clicking"))
          (t ;; menu is disabled
           (menu-item-disable expand-item)
           (menu-item-disable closet-item)
           (menu-item-disable fullscreen-item)
           (set-menu-item-title disable-item "Enable clicking")))
    ;; adjust for current closet status
    (let ((closet-row (slot-value box 'closets)))
      (if (or (null closet-row) (null (row-row-no box closet-row)))
          ;; either there's no closet or it's currently closed...
          (set-menu-item-title closet-item "Open Closet")
          (set-menu-item-title closet-item "Close Closet")))))

(defun top-right-hotspot-on? (edbox)
  (or (and *global-hotspot-control?* *top-right-hotspots-on?*)
      (and (not *global-hotspot-control?*) (top-right-hotspot-active? edbox))))

(defboxer-command com-mouse-tr-pop-up (window x y mouse-bp click-only?)
  "Pop up a box attribute menu"
  window x y ;  (declare (ignore window x y))
  ;; first, if there already is an existing region, flush it
  (reset-region) (reset-editor-numeric-arg)
  (let* ((screen-box (bp-screen-box mouse-bp))
         (box-type (box-type screen-box))
         (swid (screen-obj-wid screen-box))
         (edbox (screen-obj-actual-obj screen-box))
         (*hotspot-mouse-box* edbox)
         (*hotspot-mouse-screen-box* screen-box))
    (if (and (not click-only?)
             (mouse-still-down-after-pause? 0)) ; maybe *mouse-action-pause-time* ?
        (multiple-value-bind (left top right)
            (box-borders-widths box-type screen-box)
          (declare (ignore left))
          ;; will probably have to fudge this for type tags near the edges of
          ;; the screen-especially the bottom and right edges
          (multiple-value-bind (abs-x abs-y) (xy-position screen-box)
            (update-tr-menu edbox)
            ;; the coms in the pop up rely on this variable
            (menu-select *tr-popup* (- (+ abs-x swid) right) (+ abs-y top))))
        ;; for simple clicks we do the action (unless it is disabled)
        (when (top-right-hotspot-on? edbox) (com-hotspot-expand-box edbox screen-box))))
  eval::*novalue*)

(defvar *bl-popup* (make-instance 'popup-menu
                     :items (list (make-instance 'menu-item
                                    :title "Flip"
                                    :action 'com-hotspot-toggle-graphics)
                                  (make-instance 'menu-item
                                    :title "Disable"
                                    :action 'com-mouse-toggle-bl-hotspot))))

(defun update-bl-menu (box)
  (let ((flip-item     (car    (menu-items *bl-popup*)))
        (disable-item  (cadr   (menu-items *bl-popup*))))
    ;; adjust the menu for enable/disable info
    (cond ((or (and *global-hotspot-control?* *bottom-left-hotspots-on?*)
               (and (not *global-hotspot-control?*)
                    (bottom-left-hotspot-active? box)))
           ;; everything should be on...
           (menu-item-enable flip-item)
           (set-menu-item-title disable-item "Disable clicking"))
          (t (menu-item-disable flip-item)
             (set-menu-item-title disable-item "Enable clicking")))
    ;; now adjust for box status
    (cond ((not (graphics-box? box))
           ;; nothing for now, perhaps later we can add a dialog ADD graphics
           (menu-item-disable flip-item)
           (set-menu-item-title flip-item "No Graphics"))
          ((display-style-graphics-mode? (display-style-list box))
           (set-menu-item-title flip-item "Flip to Text"))
          (t (set-menu-item-title flip-item "Flip to Graphics")))))

(defun bottom-left-hotspot-on? (edbox)
  (or (and *global-hotspot-control?* *bottom-left-hotspots-on?*)
      (and (not *global-hotspot-control?*) (bottom-left-hotspot-active? edbox))))

(defboxer-command com-mouse-bl-pop-up (window x y mouse-bp click-only?)
  "Pop up a box attribute menu"
  window x y ;  (declare (ignore window x y))
  ;; first, if there already is an existing region, flush it
  (reset-region) (reset-editor-numeric-arg)
  (let* ((screen-box (bp-screen-box mouse-bp))
         (box-type (box-type screen-box))
         (shei (screen-obj-hei screen-box))
         (edbox (screen-obj-actual-obj screen-box))
         (*hotspot-mouse-box* edbox)
         (*hotspot-mouse-screen-box* screen-box))
    (if (and (not click-only?)
             (mouse-still-down-after-pause? 0)) ; maybe *mouse-action-pause-time* ?
        (multiple-value-bind (left top right bottom)
            (box-borders-widths box-type screen-box)
          (declare (ignore top right))
          ;; will probably have to fudge this for type tags near the edges of
          ;; the screen-especially the bottom and right edges
          (multiple-value-bind (abs-x abs-y) (xy-position screen-box)
            (update-bl-menu edbox)
            ;; the coms in the pop up rely on this variable
            (menu-select *bl-popup*
                         (+ abs-x left) (- (+ abs-y shei) bottom))))
        ;; for simple clicks we do the action (unless it is disabled)
        (when (bottom-left-hotspot-on? edbox)
          (com-hotspot-toggle-graphics edbox)))))

(defun com-hotspot-unfix-box-size (&optional (box *hotspot-mouse-box*))
  (com-unfix-box-size box))

;; THings are setup so that this menu appears ONLY if the hotspot is enabled
;; indicating that auto box sizing is active.  If manual box sizing is active
;; we go straight to com-mouse-resize-box
(defvar *br-popup* (make-instance 'popup-menu
                     :items (list (make-instance 'menu-item
                                    :title "Automatic Box Size"
                                    :action 'com-hotspot-unfix-box-size)
                                  (make-instance 'menu-item
                                    :title "Manual Box Size"
                                    :action 'com-mouse-toggle-br-hotspot))))

(defun update-br-menu (box)
  (declare (ignore box))
  (let ((auto-item    (car  (menu-items *br-popup*)))
        (manual-item  (cadr (menu-items *br-popup*))))
    ;; We only see the menu if the spot is "off", an "on" spot means resize
    ;; make sure "auto" is greyed out
    (menu-item-disable  auto-item)
    (menu-item-enable manual-item)))

;; NOTE: bottom right corner NEVER (currently) checks the global var, only
;; the local box flag is used...
;; active hotspot is interpreted to mean resizable
(defboxer-command com-mouse-br-pop-up (window x y mouse-bp click-only?)
  "Pop up a box attribute menu"
  window x y ;  (declare (ignore window x y))
  ;; first, if there already is an existing region, flush it
  (reset-region) (reset-editor-numeric-arg)
  (let* ((screen-box (bp-screen-box mouse-bp))
         (box-type (box-type screen-box))
         (swid (screen-obj-wid screen-box))
         (shei (screen-obj-hei screen-box))
         (edbox (screen-obj-actual-obj screen-box)))
    (cond ((bottom-right-hotspot-active? edbox)
           (if (or click-only? (not (mouse-still-down-after-pause? 0)))
               ;; hotspot is on, but we only got a click, shortcut to restore menu
               (progn
                 (set-fixed-size edbox nil nil)
                 (set-scroll-to-actual-row screen-box nil)
                 (modified edbox)
                 ;; turn the hotspot off so the menu will pop up next time
                 (set-bottom-right-hotspot-active? edbox nil))
               ;; otherwise, do the normal resize stuff
               (com-mouse-resize-box window x y mouse-bp click-only?)))
          (t ;; otherwise, update and present a menu
           (multiple-value-bind (left top right bottom)
               (box-borders-widths box-type screen-box)
             (declare (ignore left top))
             ;; will probably have to fudge this for type tags near the edges of
             ;; the screen-especially the bottom and right edges
             (multiple-value-bind (abs-x abs-y) (xy-position screen-box)
               (update-br-menu edbox)
               ;; the coms in the pop up rely on this variable
               (let ((*hotspot-mouse-box* edbox)
                     (*hotspot-mouse-screen-box* screen-box))
                 (menu-select *br-popup*
                              (- (+ abs-x swid) right)
                              (- (+ abs-y shei) bottom)))))))))


;;;; Type Tag Popup Menu

(defvar *tt-popup* (make-instance 'popup-menu
                     :items (list (make-instance 'menu-item
                                    :title "Flip to Doit"
                                    :action 'com-tt-toggle-type)
                                  #+(or mcl lispworks)
                                  (make-instance 'menu-item
                                    :title "Properties"
                                    :action 'com-edit-box-properties)
                                  ;; these are now all in the props dialog (mac)
                                  #-(or mcl lispworks)
                                  (make-instance 'menu-item
                                    :title "File"
                                    :action 'com-tt-toggle-storage-chunk)
                                  #-(or mcl lispworks)
                                  (make-instance 'menu-item
                                    :title "Read Only"
                                    :action 'com-tt-toggle-read-only)
                                  #-(or mcl lispworks)
                                  (make-instance 'menu-item
                                    :title "Autoload"
                                    :action 'com-tt-toggle-autoload-file))))

#+(or mcl lispworks)
(defun update-tt-menu (box)
  (let ((type-item  (car (menu-items *tt-popup*))))
    (cond ((data-box? box)
           (set-menu-item-title type-item "Flip to Doit")
           (menu-item-enable type-item))
          ((doit-box? box)
           (set-menu-item-title type-item "Flip to Data")
           (menu-item-enable type-item))
          (t
           (set-menu-item-title type-item "Flip Box Type")
           (menu-item-disable type-item)))))

;; frobs the items in the pop up to be relevant
;; more elegant to do this by specializing the menu-item-update method
;; on a tt-pop-up-menu-item class.  Wait until we hack the fonts to do this...
#-(or mcl lispworks)
(defun update-tt-menu (box)
  (let ((type-item  (car (menu-items *tt-popup*)))
        (store-item (find-menu-item *tt-popup* "File"))
        (read-item  (find-menu-item *tt-popup* "Read Only"))
        (autl-item  (find-menu-item *tt-popup* "Autoload")))
    (cond ((data-box? box)
           (set-menu-item-title type-item "Flip to Doit")
           (menu-item-enable type-item))
          ((doit-box? box)
           (set-menu-item-title type-item "Flip to Data")
           (menu-item-enable type-item))
          (t
           (set-menu-item-title type-item "Flip Box Type")
           (menu-item-disable type-item)))
    (cond ((storage-chunk? box)
           (set-menu-item-check-mark store-item t)
           ;; enable the other menu items in case they have been previously disabled
           (menu-item-enable read-item)
           (menu-item-enable autl-item))
          (t (set-menu-item-check-mark store-item nil)
             ;; disable remaining items because they only apply to storage-chunks
             (menu-item-disable read-item)
             (menu-item-disable autl-item)))
    ;; synchronize the remaining items, even if they are disabled, they
    ;; should still reflect the current values of the box
    (set-menu-item-check-mark read-item (read-only-box? box))
    (set-menu-item-check-mark autl-item (autoload-file? box))))

(defboxer-command com-mouse-type-tag-pop-up (window x y mouse-bp click-only?)
  "Pop up a box attribute menu"
  window x y ;  (declare (ignore window x y))
  ;; first, if there already is an existing region, flush it
  (reset-region) (reset-editor-numeric-arg)
  (let* ((screen-box (bp-screen-box mouse-bp))
         (box-type (box-type screen-box))
         (shei (screen-obj-hei screen-box))
         (edbox (box-or-port-target (screen-obj-actual-obj screen-box))))
    (when (and (not click-only?)
               (mouse-still-down-after-pause? 0)) ;maybe *mouse-action-pause-time* ?
      (multiple-value-bind (left top right bottom)
          (box-borders-widths box-type screen-box)
        (declare (ignore top right))
        ;; will probably have to fudge this for type tags near the edges of
        ;; the screen-especially the bottom and right edges
        (multiple-value-bind (abs-x abs-y) (xy-position screen-box)
          (update-tt-menu edbox)
          ;; the coms in the pop up rely on this variable
          (let ((*hotspot-mouse-box* edbox))
            (menu-select *tt-popup*
                         (+ abs-x left) (- (+ abs-y shei) bottom)))))))
  eval::*novalue*)

