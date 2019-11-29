; -*- Mode:LISP; Syntax: Common-Lisp; Package:BOXER; Base:8.-*- 
#|


   $Header$

   $Log$


 Copyright 1991 - 1998 Regents of the University of California

 Enhancements and Modifications Copyright 1998 - 2003 PyxiSystems LLC


                                         +-Data--+
                This file is part of the | BOXER | system
                                         +-------+



   This file contains the low level drawing primitives for the REDISPLAY
   which are machine independent but expect to do any clipping in software.
   The clipping calculations are done BEFORE any drawing and only unclipped
   parts are actually drawn.

   The complement of this file is the the draw-high-software-clipping.lisp

   All window coordinate parameters in this file are "local".  That is
   they are relative to the containing screen structure (screen-row or
   screen-box) and should only be called within the proper clipping and
   scaling macros.

   This file should be used by on top of draw-low-xxx files which
   support fast hardware clipping.  The redisplay will setup a
   new clipping environment for EVERY level of box and row.

   It should be possible to recompile the system after changing which
   draw-high-xxx-clipping.lisp file to use in the boxsys.lisp file
   to see which version is faster.

   This file is meant to coexist with various
   "xxx-draw-low" files which are the machine specific primitives.


Modification History (most recent at top)

 2/11/03 merged current LW and MCL source
 5/02/01 allow for software clipping in %bitblt ops for LWWIN in bitblt-move-region
 4/03/01 draw-string now calls %draw-string with explicit parameter %drawing-window
         this fixes bug where draw-string inside drawing-on-bitmap on PC would
         draw to the screen instead of the bitmap
 6/05/00 with-turtle-clipping changed for LW port
 5/11/98 added comment describing change to interpretation of x,y in draw-cha
 5/11/98 started logging: source = boxer version 2.3


|#

#-(or lispworks mcl lispm) (in-package 'boxer :use '(lisp) :nicknames '(box))
#+(or lispworks mcl)       (in-package :boxer)


;;;; Scaling and Clipping Macros

;;; origin gets reset in hardware by scaling macros so these are no ops
;;; They need to be defined because other functions (usually sprite graphics)
;;; will use them explicitly to convert coords.

(defmacro scale-x (x) x)
(defmacro scale-y (y) y)

(defmacro clip-x (scaled-x) scaled-x)
(defmacro clip-y (scaled-y) scaled-y)

;; Since we have hardware clipping we'll just go ahead an draw stuff even
;; if it is out of bounds
(defmacro x-out-of-bounds? (scaled-x)
  (declare (ignore scaled-x))
  nil)

(defmacro y-out-of-bounds? (scaled-y)
  (declare (ignore scaled-y))
  nil)

;;; Interface functions WINDOW-PARAMETERS-CHANGED, WITH-DRAWING.  UPDATE-WINDOW-SYSTEM-STATE
;;; must be defined by the window system code.

; **** no longer used, see draw-low-mcl for details
;(defmacro with-drawing (&body body)
;  `(progn
;     (update-window-system-state)    
;     ,@body))

;;; Wrap this around the body of let forms that bind clipping variables. 
;;; Now a no-op, but a more efficient implementation might make use of this.
;(defmacro with-clip-bindings (&body body)
;  `(progn ,@body))

;;; Macros from draw-high, slightly altered

(defmacro drawing-on-window-bootstrap-clipping-and-scaling ((x y wid hei) &body body)
  `(let* ((%origin-x-offset ,x) (%origin-y-offset ,y)
          ;; absolute clipping parameters
          (%clip-lef ,x) (%clip-top ,y)
	  (%clip-rig (+& %clip-lef ,wid)) (%clip-bot (+& %clip-top ,hei))
          ;; relative clipping parameters
          (%local-clip-lef 0)    (%local-clip-top 0)
          (%local-clip-rig ,wid) (%local-clip-bot ,hei))
     %clip-rig %clip-bot %origin-x-offset %origin-y-offset ;bound but never...
     %local-clip-lef %local-clip-top %local-clip-rig %local-clip-bot
;     ;; **** since we are letting the hardware do the clipping, be sure
;     ;; to include the forms that invoke the hardware
;     (unwind-protect
;         (progn (window-system-dependent-set-origin %origin-x-offset
;                                                    %origin-y-offset)
                ,@body))
;      ;; return to some canonical state
;       (window-system-dependent-set-origin 0 0))))


;; **** this is the reverse of the software version because the
;; WITH-CLIPPING-INSIDE macro should use the new coordinate system
;; set by WITH-ORIGIN-AT
(defmacro with-drawing-inside-region ((x y wid hei) &body body)
  `(with-origin-at (,x ,y)
     (with-clipping-inside (0 0 ,wid ,hei)
       . ,body)))

;; **** changed, see draw-low-mcl for details...
#-opengl
(defmacro with-origin-at ((x y) &body body)
  `(unwind-protect
     (let ((%origin-x-offset (+& %origin-x-offset ,x))
           (%origin-y-offset (+& %origin-y-offset ,y)))
       (window-system-dependent-set-origin %origin-x-offset %origin-y-offset)
       . ,body)
     ;; make sure it gets reset to the old value
     (window-system-dependent-set-origin %origin-x-offset %origin-y-offset)))

;; Opengl set-origin is RELATIVE !
#+opengl
(defmacro with-origin-at ((x y) &body body)
  (let ((fx (gensym)) (fy (gensym)) (ux (gensym)) (uy (gensym)))
    `(let* ((,fx (float ,x)) (,fy (float ,y))
            (,ux (float-minus ,fx)) (,uy (float-minus ,fy))
            ;; keep track of scaling because bitblt doesn't respect OpenGL translation
            (%origin-x-offset (+ %origin-x-offset ,x))
            (%origin-y-offset (+ %origin-y-offset ,y)))
       (unwind-protect
           (progn
             (window-system-dependent-set-origin ,fx ,fy)
             . ,body)
         (window-system-dependent-set-origin ,ux ,uy)))))

;; **** changed, see draw-low-mcl for details...
(defmacro with-clipping-inside ((x y wid hei) &body body)
  `(with-window-system-dependent-clipping (,x ,y ,wid ,hei) . ,body))

;; do we need to readjust the clip region here ????
(defmacro with-scrolling-origin ((scroll-x scroll-y) &body body)
  `(with-origin-at (,scroll-x ,scroll-y)
     . ,body))

;;; This MUST use the hardware clipping regardless of speed.
;;; It is used only around bodies which do sprite graphics 
;;; so the frequency of use is MUCH less than it is in the redisplay
;;;
;;; this adjusts the clipping to be width and height AT the current
;;; scaled origin
;;;
(defmacro with-turtle-clipping ((wid hei . args) &body body)
  `(with-window-system-dependent-clipping (0 0 ,wid ,hei . ,args) . ,body))

;;; Drawing functions

;;; sure there were no intervening clipping operations.

(defun draw-line (x0 y0 x1 y1 alu end-point?)
  (%draw-line x0 y0 x1 y1 alu end-point? %drawing-window))

(defun draw-rectangle (alu w h x y)
  (%draw-rectangle w h x y alu %drawing-window))

(defun erase-rectangle (w h x y)
  (%erase-rectangle w h x y %drawing-window))

;; useful for debugging erase-rectangle lossage
(defun flash-rectangle (w h x y)
  (dotimes (i 6)
    (%draw-rectangle w h x y  alu-xor %drawing-window)
    (sleep .1)))

(defun bitblt-tile-to-screen (alu wid hei tile to-x to-y)
  (%bitblt-tile-to-screen alu wid hei tile %drawing-array to-x to-y))

(defun bitblt-to-screen (alu wid hei from-array from-x from-y to-x to-y)
  (%bitblt-to-screen alu wid hei from-array from-x from-y to-x to-y))

(defun bitblt-from-screen (alu wid hei to-array from-x from-y to-x to-y)
  (%bitblt-from-screen alu wid hei to-array from-x from-y to-x to-y))

(defun bitblt-within-screen (alu full-wid full-hei from-x from-y to-x to-y)
  (let (;; hardware clipping is only performed on the destination
        ;; rect, so we have to make sure we don't pull in any
        ;; pixels from outside the clipping region from the source rect
        (wid (min& full-wid (-& %local-clip-rig from-x)))
        (hei (min& full-hei (-& %local-clip-bot from-y))))
    (%bitblt-in-screen alu wid hei
		       %drawing-array from-x from-y to-x   to-y)))

(defun bitblt-move-region (full-wid full-hei from-x from-y delta-x delta-y)
  (let (;; hardware clipping is only performed on the destination
        ;; rect, so we have to make sure we don't pull in any
        ;; pixels from outside the clipping region from the source rect
        (wid (min& full-wid (-& %clip-rig from-x)))
        (hei (min& full-hei (-& %clip-bot from-y))))    
    (unless (or (zerop full-wid) (zerop full-hei))
    (%bitblt-in-screen alu-seta wid hei
		       %drawing-array from-x from-y
		       (+& from-x delta-x) (+& from-y delta-y))
    ;; Now we erase the part of the screen which is no longer covered.
    (unless (zerop delta-x)
      (erase-rectangle (abs delta-x) hei
		       (cond ((plusp delta-x) from-x)
			     ((>& (abs delta-x) wid) from-x)
                             #+lwwin
                             ;;If the region we're moving is partly
			     ;;not displayed due to clipping we have to
			     ;;clear out stuff specially.  This has a
			     ;;few bugs but it works better than with
			     ;;out it.
                             ;; NOTE: this is because LW does software clipping for
                             ;; %bitblt ops
			     ((>& (+& wid from-x  %origin-x-offset) %clip-rig)
			      (+& %clip-rig delta-x (-& %origin-x-offset)))
			     (t (+& from-x wid delta-x)))
		       from-y))
    (unless (zerop delta-y)
      (erase-rectangle wid (abs delta-y)
		       from-x
		       (cond ((plusp delta-y) from-y)
			     ((>& (abs delta-y) hei) from-y)
                             #+lwwin
                             ;; same software clipping stuff, doo dah doo dah...
                             ((>& (+& hei from-y %origin-y-offset) %clip-bot)
			    (+& %clip-bot delta-y (-& %origin-y-offset)))
			     (t (+& from-y hei delta-y))))))))

;; NOTE: in the new multi font world, draw-cha needs to draw at the char's
;; baseline rather than the top left corner.  This is because in a multifont
;; row, the common reference point will be the baseline instead of the top
;; edge
(defun draw-cha (alu char x y)
  (%draw-cha alu x y char))

(defun draw-string (alu font-no string region-x region-y &optional window)
  (declare (ignore window))
  (%draw-string alu font-no string region-x region-y %drawing-window))
  



#| ;these should now be handled in draw-high-common.lisp

(defun draw-point (alu x y)
  (%draw-point x y alu %drawing-window))

(defun draw-arc (alu x y wid hei start-angle sweep-angle)
  (%draw-arc %drawing-window alu x y wid hei start-angle sweep-angle))

(defun draw-filled-arc (alu x y wid hei start-angle sweep-angle)
  (%draw-filled-arc %drawing-window alu x y wid hei start-angle sweep-angle))

;;; the points arg is in the form of ((x0 . y0) (x1 . y1)...) pairs
(defun draw-poly (alu points)
  (unless (null points)
    (with-drawing
      (%draw-poly (boxer-points->window-system-points points
						      (x x)
						      (y y))
                  alu %drawing-window))))

|#