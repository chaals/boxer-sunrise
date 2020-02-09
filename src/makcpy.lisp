;;; -*- Package: BOXER; Mode: LISP; Base: 10.; Syntax: Common-Lisp -*-

#|


 $Header: makcpy.lisp,v 1.0 90/01/24 22:14:32 boxer Exp $

 $Log:	makcpy.lisp,v $
;;;Revision 1.0  90/01/24  22:14:32  boxer
;;;Initial revision
;;;

    Boxer
    Copyright 1985-2020 Andrea A. diSessa and the Estate of Edward H. Lay

    Portions of this code may be copyright 1982-1985 Massachusetts Institute of Technology. Those portions may be
    used for any purpose, including commercial ones, providing that notice of MIT copyright is retained.

    Licensed under the 3-Clause BSD license. You may not use this file except in compliance with this license.

    https://opensource.org/licenses/BSD-3-Clause


                                   +-Data--+
          This file is part of the | BOXER |  System
                                   +-------+


  This file contains code for copying and making Editor Objects quickly.


Modification History (most recent at top)

12/15/11 text-string for row now returns second value of T when a box is encountered
 2/22/09 copy-graphics-sheet
 3/16/07 copy-special-box-properties now hacks graphics-info paradigm
 2/15/03 merged current LW and MCL files
 2/12/02 added bitmap dirty? handling to copy-graphics-sheet
 2/16/01 merged current LW and MCL files
10/01/99 copy-secial-box-properties: fix to bug where copy-thing (comsa.lisp) copies
         with top-level attributes flag set to :name and pathnames of unfilled file
         boxes are not copied
4/05/99 added #+lispworks for text-string methods
 5/03/98 changed copy-row to also copy FD's
 5/03/98 starting logging: source = boxer 2.3


|#

#-(or lispworks mcl Lispm) (in-package 'boxer :use '(lisp) :nicknames '(box))
#+(or lispworks mcl)       (in-package :boxer)



;;;;COPYing

(defun copy-top-level-box (box &optional copy-top-level-props)
  (with-editor-port-relinking (copy-box box copy-top-level-props)))


(defun copy-graphics-sheet (from-sheet new-superior-box)
  (let* ((wid (graphics-sheet-draw-wid from-sheet))
         (hei (graphics-sheet-draw-hei from-sheet))
         (new-sheet (make-graphics-sheet wid hei new-superior-box)))
    (when (not (null (graphics-sheet-graphics-list from-sheet)))
      (setf (graphics-sheet-graphics-list new-sheet)
	    (copy-graphics-command-list
	     (graphics-sheet-graphics-list from-sheet))))
    (setf (graphics-sheet-background new-sheet)
	  (graphics-sheet-background from-sheet))
    (setf (graphics-sheet-draw-mode new-sheet)
	  (graphics-sheet-draw-mode from-sheet))
    (when (not (null (graphics-sheet-bit-array from-sheet)))
      (let ((bm (make-offscreen-bitmap *boxer-pane* wid hei)))
        (setf (graphics-sheet-bit-array new-sheet) bm)
        (with-graphics-vars-bound-internal from-sheet
          #-opengl
          (drawing-on-bitmap (bm)
            (with-pen-color ((or (graphics-sheet-background from-sheet)
                                 *background-color*))
              (draw-rectangle alu-seta %drawing-width %drawing-height 0 0))
            (bitblt-to-screen alu-seta wid hei (graphics-sheet-bit-array from-sheet)
                              0 0 0 0))
          #+opengl
	  (copy-offscreen-bitmap alu-seta wid hei (graphics-sheet-bit-array from-sheet) 0 0 bm 0 0)
          ;; mark the dirty? flag
          (setf (graphics-sheet-bit-array-dirty? new-sheet) t)
          )))
    new-sheet))

(defmethod copy-box ((from-box box) &optional (copy-top-level-attributes? t))
  (let ((to-box (make-uninitialized-box (class-name (class-of from-box)))))
    (shared-initialize to-box t)
    ;(set-class to-box (class-of from-box))
    (copy-special-box-properties from-box to-box copy-top-level-attributes?)
    (copy-box-internal from-box to-box)
    to-box))

(defmethod new-flags-for-copy ((self box) &optional (copy-top-level-attributes? t))
  (let ((flags (slot-value self 'flags))
        (fir (slot-value self 'first-inferior-row)))
    ;; these flags always get unset
    (setq flags (set-box-flag-fake-file-box
		 (set-box-flag-build-template? flags nil) nil))
    (when (and (box-flag-storage-chunk? flags) (null fir)
               (not (box-flag-read-only-box? flags)))
      (setq flags (set-box-flag-copy-file? flags t)))
    ;; remove RO flag if we are copying a box with contents...
    (when (and (not (eq copy-top-level-attributes? T))
               ;; copy-top-level-attributes? can be various keywords which we aren't
               ;; interested in here but which means we can't just check for nil
               (box-flag-read-only-box? flags))
      (setq flags (set-box-flag-read-only-box? flags nil)))
    flags))

(defvar *copy-special-box-properties-hook* nil)

(defmethod copy-special-box-properties ((from-box box) to-box
					&optional
					(copy-top-level-attributes? t))
  ;; display style...
  (set-display-style-list to-box (copy-display-style (display-style-list from-box)))
  ;; there should be a better way to do this, like maybe
  ;; moving the dashed border attribute into a flag ?
  (setf (display-style-border-style (display-style-list to-box)) nil)
  (let ((new-flags (new-flags-for-copy from-box copy-top-level-attributes?)))
    (setf (slot-value to-box 'flags) new-flags)
    (when (box-flag-storage-chunk? new-flags)
      (setf (display-style-border-style (display-style-list to-box)) ':thick)
      (when (and (or (box-flag-read-only-box? new-flags)
                     (null (first-inferior-row from-box)))
                 (not (null copy-top-level-attributes?))
                 ;(eq copy-top-level-attributes? t)
                 ;; fix to bug where copy-thing (comsa.lisp) copies with top-level
                 ;; attributes flag set to :name and pathnames of unfilled file
                 ;; boxes are not copied
                 )
        ;; if the box is READ Only or hasn't been filled, then we copy filling
        ;; information--pathname or url and boxtop if there is one
        ;; Note that this sort of breaks the copying model since different things
        ;; can happen to RW file inferiors depending on whether they are filled
        (let ((af (getprop from-box :associated-file)))
          (unless (null af) (putprop to-box af :associated-file)))
        (let ((url (getprop from-box :url)))
          (unless (null url)
            ;; may need to change this if we decide that exports should be
            ;; copied at top level (in copy-thing in comsa.lisp)
            (putprop to-box (boxnet::copy-url url) :url))))))
  (let ((bt (getprop from-box :boxtop)))
    (unless (null bt) (putprop to-box bt :boxtop)))
  (when (copy-file? to-box)
    (boxnet::record-copy-file-info from-box to-box))
  ;; graphics...
  (let ((gi (slot-value from-box 'graphics-info)))
    (cond ((null gi))
          ((graphics-sheet? gi)
           (setf (graphics-info to-box)
                 (copy-graphics-sheet (graphics-sheet from-box) to-box)))
          ((graphics-object? gi)
           (let ((new-graphics-object
                  (cond ((null (slot-value from-box 'graphics-info))
                         (warn "There doesn't seem to be an associated turtle for ~A"
                               from-box)
                         (make-turtle))
                        (t (copy-graphics-object gi)))))
             (setf (graphics-info to-box) new-graphics-object)
             (set-sprite-box new-graphics-object to-box)))))
  (when (not (null (av-info from-box)))
    (putprop to-box (copy-av-info (av-info from-box)) 'av-info))
  ;; other special properties...
  (dolist (pfun *copy-special-box-properties-hook*) (funcall pfun from-box to-box))
  ;; Copying these depend on whether we are at top level or not
  (unless (null copy-top-level-attributes?)
    ;; copy any export info
    (unless (or (null (exports from-box))
		(not (or (eq copy-top-level-attributes? t)
			 (eq copy-top-level-attributes? ':exports))))
      (set-exports to-box (exports from-box))
      ;; make sure the box looks right
      (setf (display-style-border-style (display-style-list to-box))
            (if (storage-chunk? to-box)
              :thick-dashed
	      ':dashed)))
    ;; and the name
    (let ((name (slot-value from-box 'name)))
      (unless (or (null name)
		  (not (or (eq copy-top-level-attributes? t)
			   (eq copy-top-level-attributes? ':name))))
	(set-name to-box (make-name-row `(,(if (stringp name) name
					       (text-string name)))))))))

(defmethod copy-box ((port port-box) &optional (copy-top-level-attributes? t))
  (let ((new-port (make-initialized-box :type 'port-box))
	(target (ports port)))
    (copy-special-box-properties port new-port copy-top-level-attributes?)
    (set-port-to-box new-port target)
    (let ((target-pair (assoc target .link-target-alist.)))
      (if (null target-pair)
	  (push new-port .port-copy-list.)
	  (set-port-to-box new-port (cdr target-pair))))
    new-port))

(defun copy-box-internal (from-box to-box)
  (let* ((from-previous-row nil)
	 (from-closets (slot-value from-box 'closets))
	 (first-apparent-row (first-inferior-row from-box))
	 (from-current-row (if (and (eq first-apparent-row from-closets)
				    (not (null first-apparent-row)))
			       (next-row first-apparent-row)
			       first-apparent-row))
	 (to-previous-row nil)
	 (to-current-row (if (null from-current-row)
			     (make-row '())
			     (copy-row from-current-row nil to-box))))
    ;;Copy the various parameters.
    (unless (null from-closets)
      (add-closet-row to-box (copy-row from-closets nil to-box)))
    (unless (null first-apparent-row)
      ;; Begin with the to-box owning the first row and with no previous row
      (insert-row-at-row-no to-box to-current-row 0)
      (loop
       ;; If there's a previous row, tell it and the
       ;; current row about each other.
       (unless (null to-previous-row)
	 (insert-row-after-row to-box to-current-row to-previous-row))
       ;; Relegate the current row to the status of previous row.
       (setq to-previous-row to-current-row
	     from-previous-row from-current-row)
       ;; Get the next row to copy.  If it's not there,
       ;; then we're done making new rows.
       ;; Otherwise, make a new row and make that be the current row.
       (setq from-current-row (unless (null from-previous-row)
				(next-row from-previous-row)))
       (if (null from-current-row) (return))
       ;; The previous-row of the newly-made row is being set here and above.
       ;; Which is right?
       (setq to-current-row
	     (copy-row from-current-row to-previous-row to-box))))
    ;; handle port KLUDGE.
    (when (not-null (ports from-box))
      (push (cons from-box to-box) .link-target-alist.))
    to-box))

;;;This moves the internals of the from-box to the to-box
;; the fast version bypasses the insert-self-action
;; mechanism, use with caution
(defun move-box-internals (from-box to-box &optional (fast t))
  (let* ((from-closets (slot-value from-box 'closets))
	 (first-apparent-row (first-inferior-row from-box))
	 (from-current-row (if (and (eq first-apparent-row from-closets)
				    (not (null first-apparent-row)))
			       (next-row first-apparent-row)
			       first-apparent-row)))
    (unless (null from-closets)
      (setf (slot-value to-box 'closets) from-closets)
      (set-superior-box from-closets to-box))
    (cond ((not (null fast))
	   (unless (null first-apparent-row)
	     ;; Begin with the to-box owning the first row
	     ;; and with no previous row
	     (setf (slot-value to-box 'first-inferior-row) from-current-row)
	     (setf (slot-value from-box 'first-inferior-row) nil))
	   ;; explicitly move the bindings since we are bypassing the
	   ;; insert-self protocols when moving the rows over.
	   (setf (slot-value to-box 'static-variables-alist)
		 (slot-value from-box 'static-variables-alist)
		 (slot-value from-box 'static-variables-alist)
		 nil)
	   ;; explicitly move triggers since we are bypassing the
	   ;; insert-self protocols
	   (setf (slot-value to-box   'current-triggers)
		 (slot-value from-box 'current-triggers)
		 (slot-value to-box   'trigger-cache)
		 (slot-value from-box   'trigger-cache))
	   (do ((row from-current-row (next-row row)))
	       ((null row))
	     (setf (superior-box row) to-box)))
	  ((not (null first-apparent-row))
	   (let ((next-row nil))
	     (do ((row first-apparent-row next-row))
		 ((null row))
	       (setq next-row (next-row row))
	       (append-row to-box row)))))))


(DEFUN COPY-ROW (FROM-ROW &OPTIONAL NEW-PREVIOUS-ROW NEW-SUPERIOR-BOX
                          (copy-box-args nil c-b-a-supplied?))
  (LET ((NEW-ROW (MAKE-UNINITIALIZED-ROW)))
    (setf (actual-obj-tick new-row) -1)
    (SETF (SUPERIOR-BOX NEW-ROW) NEW-SUPERIOR-BOX)
    (SETF (PREVIOUS-ROW NEW-ROW) NEW-PREVIOUS-ROW)
    (SETF (CHAS-ARRAY NEW-ROW)
          (if c-b-a-supplied?
            (COPY-CHAS-ARRAY (CHAS-ARRAY FROM-ROW) NEW-ROW copy-box-args)
            (copy-chas-array (chas-array from-row) new-row)))
    NEW-ROW))

;; this is rebound inside of the VC printer because deep inferiors of
;; editor boxes may need to render their contents using the VC access mechanism
(defvar *recursive-copy-box-function* #'copy-box)

(defun copy-chas-array (from-chas new-row &optional (copy-box-args
                                                     nil copy-box-arg-supplied?))
  (with-fast-chas-array-manipulation (from-chas fast-from-chas)
    (flet ((make-length-n-chas-array (n)
	     (let ((array (make-chas-array (max& *chas-array-default-size* n))))
	       (setf (chas-array-active-length array) n)
	       array)))
	(let* ((length (chas-array-active-length from-chas))
	       (to-chas (make-length-n-chas-array length)))
	  (with-fast-chas-array-manipulation (to-chas fast-to-chas)
	    (dotimes& (index length)
	      (if (cha? (fast-chas-array-get-cha fast-from-chas index))
		  (setf (fast-chas-array-get-cha fast-to-chas index)
			(fast-chas-array-get-cha fast-from-chas index))
		  (setf (fast-chas-array-get-cha fast-to-chas index)
			(let ((new-box (if copy-box-arg-supplied?
                                           (funcall *recursive-copy-box-function*
					            (fast-chas-array-get-cha
					             fast-from-chas index)
                                                    copy-box-args)
                                           (funcall *recursive-copy-box-function*
					            (fast-chas-array-get-cha
					             fast-from-chas index)))))
			  (setf (superior-row new-box) new-row)
			  new-box))))
            (setf (chas-array-fds to-chas)
                  (mapcar #'(lambda (fd) (make-cfd (bfd-cha-no  fd)
                                                   (bfd-font-no fd)
                                                   (bfd-color   fd)))
                          (chas-array-fds from-chas)))
	    to-chas)))))



;;;;MAKE-mumble functions
;;; these should ONLY BE USED to CONS NEW STRUCTURE !!!
;;; in particular, if you pass a box that is already in the editor
;;; hierarchy to any of the make-mumble functions, you will lose
;;; horribly (maybe not right away but eventually it WILL catch up with you)

(defun fast-string-into-chas-array (string ca)
  ;(declare (simple-string string))
  (let ((sl (length string))
	(cl (chas-array-active-length ca)))
    (chas-array-assure-room ca (+& cl sl))
    (with-fast-chas-array-manipulation (ca chas)
      (dotimes& (i sl)
	(setf (aref chas (+& cl i)) (aref string i)))
      (setf (chas-array-active-length ca) (+& cl sl)))))

(defun make-row-from-string (string)
  (let* ((new-row (make-initialized-row))
	 (ca (chas-array new-row))
	 (sl (length string))
	 (al sl)
	 (ca-idx 0))
    (chas-array-assure-room ca al)
    (do ((idx 0 (1+& idx)))
        ((>=& idx sl))
      (let ((cha (aref string idx)))
	(cond ((char= cha #\tab)
	       ;; hack tabs to be 8 spaces
	       (let ((tab-spaces (-& 8 (mod ca-idx 8))))
		 (incf& al (1-& tab-spaces))  (chas-array-assure-room ca al)
		 (dotimes& (i tab-spaces)
		   (setf (aref (chas-array-chas ca) ca-idx) #\space)
                   (incf& ca-idx))))
	      ((or (char= cha #\return) (char= cha #\newline))
	       ;; ignore CR's and NL's
	       (decf& al))
	      (t
	       (setf (aref (chas-array-chas ca) ca-idx) cha) (incf& ca-idx)))))
    (setf (chas-array-active-length ca) (max& al 0))
    new-row))

(defun fast-chas-array-append-cha (ca c)
  (let ((cal (chas-array-active-length ca)))
    (chas-array-assure-room ca (+& cal 1))
    (with-fast-chas-array-manipulation (ca chas)
      (setf (aref chas cal) c)
      (setf (chas-array-active-length ca) (1+& cal)))))

(defun make-row (list)
  (let* ((new-row (make-initialized-row))
	 (ca (chas-array new-row))
	 (idx 0)
	 (length (length list)))
    (dolist (item list)
      (cond ((numberp item)
	     (fast-string-into-chas-array (format nil "~a" item) ca))
	    ((stringp item)
	     (fast-string-into-chas-array item ca))
	    ((symbolp item)
	     (fast-string-into-chas-array (symbol-name item) ca))
	    ((characterp item) (fast-chas-array-append-cha ca item))
	    ((box? item)
	     (fast-chas-array-append-cha ca item)
	     (set-superior-row item new-row))
	    (t (error "Don't know how to make a row out of ~S" item)))
      (incf& idx)
      (unless (=& idx length)
	(fast-chas-array-append-cha ca #\space)))
    new-row))

(defun make-name-row (list &optional (cached-name nil))
  (let* ((new-row (make-instance 'name-row :cached-name cached-name))
	 (ca (chas-array new-row))
	 (idx 0)
	 (length (length list)))
    (dolist (item list)
      (cond ((numberp item)
	     (fast-string-into-chas-array (format nil "~a" item) ca))
	    ((stringp item)
	     (fast-string-into-chas-array item ca))
	    ((symbolp item)
	     (fast-string-into-chas-array (symbol-name item) ca))
	    ((box? item) (error "You must be losing to put ~A here" item))
	    (t (error "Don't know how to make a row out of ~S" item)))
      (incf& idx)
      (unless (=& idx length)
	(fast-chas-array-append-cha ca #\space)))
    new-row))

(defun make-box (rows &optional (type 'data-box) name)
  (let ((box (make-uninitialized-box type))
	(last-row (if (row? (car rows)) (car rows) (make-row (car rows)))))
    ;; Note that the box initialize method IS NOT BEING CALLED
    ;; because we DON'T WANT TO CONS up a first-inferior-row
    ;; so we have to manually call the parts of the initialize method
    ;; that we need like...
    (shared-initialize box t)
    ;;...and...
    (setf (slot-value box 'display-style-list) (make-display-style))
    (insert-row-at-row-no box last-row 0)
    (do* ((rows-to-go (cdr rows) (cdr rows-to-go))
	  (row (car rows-to-go) (car rows-to-go)))
	 ((null rows-to-go))
      (let ((row-to-insert (if (row? row) row (make-row row))))
	(insert-row-after-row box row-to-insert last-row)
	(setq last-row row-to-insert)))
    (unless (null name)
      (set-name box (make-name-row `(,name))))
    box))





#|
;; Yuck, this is an example of how NOT to do this, it iterates over
;; the characters at least 4 (!) times
(defmethod text-string ((row row))
  (let* ((chas (chas row))
	(NO-OF-BOXES (COUNT-IF #'BOX? CHAS)))
    (IF (ZEROP NO-OF-BOXES)
	(let ((string (make-array (length chas)
				   :ELEMENT-TYPE
				   #-(or mcl symbolics) 'STRING-CHAR
				   #+(or mcl symbolics) 'character)))
	  (do ((i 0 (1+ i))
	       (chas chas (cdr chas)))
	      ((null chas))
	      (setf (aref string i)
		    #+(or symbolics mcl) (car chas)
		    #-(or symbolics mcl) (make-char (car chas))))
	  string)
	(let ((return-string (make-array (+& (length chas) no-of-boxes)
					 :element-type
					 #-(or mcl symbolics) 'string-char
					 #+(or mcl symbolics) 'character
					 :fill-pointer 0)))
	  (dolist (cha chas (values return-string t))
	    (cond ((cha? cha) (vector-push cha return-string))
		  (t
		   (vector-push #\[ return-string)
		   (vector-push #\] return-string))))))))

;; too much CONSing...
(defmethod text-string ((box box))
  (let ((return-string ""))
    (do-box-rows ((row box))
       (if (eq row (first-inferior-row box))
	   (setq return-string (text-string row))
	   (setq return-string (concatenate 'string
					    return-string
					    (make-string 1 :initial-element #\return)
					    (text-string row)))))
    return-string))

|#

(defmethod text-string ((row row)
                        &optional (return-string
                                   (make-array (length-in-chas row)
                                               :element-type
                                               #-(or mcl lispworks symbolics)
                                               'string-char
                                               #+(or mcl lispworks symbolics)
                                               'character
                                               :fill-pointer 0
                                               :adjustable t)))
  (let ((box-encountered? nil))
    (do-row-chas ((c row))
      (cond ((box? c)
             (vector-push-extend #\[ return-string)
             (vector-push-extend #\] return-string)
             (setq box-encountered? T))
            (t (vector-push-extend c return-string))))
    (if box-encountered?
        (values return-string T)
      return-string)))

(defmethod text-string ((box box) &optional return-string)
  (let ((text-length (1-& (with-summation   ; 1- to remove last #\return
                             (do-box-rows ((r box))
                               ;; 1+ for #\return
                               (sum (1+& (length-in-chas r))))))))
    (when (null return-string)
      (setq return-string (make-array text-length
                                      :element-type
                                      #-(or mcl lispworks symbolics) 'string-char
                                      #+(or mcl lispworks symbolics) 'character
                                      :fill-pointer 0 :adjustable t)))
    (do ((row (first-inferior-row box) (next-row row)))
        ((null row))
      (text-string row return-string)
      (unless (null (next-row row)) ; true for the last row
        (vector-push-extend #\return return-string))))
  return-string)


#|  (originally from emanip.lisp ) this still needs to be converted....

(DEFUN MAKE-BOX-FROM-STRING (STRING)
  "make a box from a string.  carriage returns start new rows.  this is the inverse function
to the :TEXT-STRING method of boxes. "
  (MAKE-BOX
    (LOOP WITH START = 0
	  FOR INDEX FROM 0 TO (1- (LENGTH STRING))
	  FOR CHA = (AREF STRING INDEX)
	  WHEN (OR (CHAR= CHA #\CR) (CHAR= CHA #\LINE))
	    COLLECT (LIST (NSUBSTRING STRING START INDEX)) INTO ROWS
	  WHEN (OR (CHAR= CHA #\CR) (CHAR= CHA #\LINE))
	    DO (SETQ START (1+ INDEX))
	  FINALLY
	    (RETURN (APPEND ROWS (LIST (LIST (NSUBSTRING STRING START INDEX))))))))




;;;;BOX-EQUAL
(DEFUN BOX-EQUAL (BOX1 BOX2)
  (EQUAL BOX1 BOX2))

(DEFUN ROW-EQUAL (ROW1 ROW2)
  (EQUAL ROW1 ROW2))

;(DEFMETHOD (BOX :EQUL) (BOX)
;  (LET ((MY-LENGTH-IN-ROWS (LENGTH-IN-ROWS SELF))
;	(HE-LENGTH-IN-ROWS (LENGTH-IN-ROWS BOX)))
;    (COND ((NOT (= MY-LENGTH-IN-ROWS HE-LENGTH-IN-ROWS)) NIL)
;	  (T
;	   (DO* ((ROW-NO 0 (+ ROW-NO 1))
;		 (MY-ROW (ROW-AT-ROW-NO SELF ROW-NO) (ROW-AT-ROW-NO SELF ROW-NO))
;		 (HE-ROW (ROW-AT-ROW-NO BOX ROW-NO) (ROW-AT-ROW-NO BOX ROW-NO)))
;		((>= ROW-NO MY-LENGTH-IN-ROWS) T)
;	     (OR (EQUAL MY-ROW HE-ROW)
;		 (RETURN NIL)))))))
;
;(DEFMETHOD (ROW :EQUL) (ROW)
;  (LET ((MY-LENGTH-IN-CHAS (LENGTH-IN-CHAS SELF))
;	(HE-LENGTH-IN-CHAS (LENGTH-IN-CHAS ROW)))
;    (COND ((NOT (= MY-LENGTH-IN-CHAS HE-LENGTH-IN-CHAS)) NIL)
;	  (T
;	   (DO* ((CHA-NO 0 (+ CHA-NO 1))
;		 (MY-CHA (CHA-AT-CHA-NO SELF CHA-NO) (CHA-AT-CHA-NO SELF CHA-NO))
;		 (HE-CHA (CHA-AT-CHA-NO ROW CHA-NO) (CHA-AT-CHA-NO ROW CHA-NO)))
;		((>= CHA-NO MY-LENGTH-IN-CHAS) T)
;	     (COND ((AND (BOX? MY-CHA) (BOX? HE-CHA))
;		    (IF (NOT (EQUAL MY-CHA HE-CHA))
;			(RETURN NIL)))
;		   ((= (CHAR-CODE MY-CHA) (CHAR-CODE HE-CHA))
;		    T)
;		   (T (RETURN NIL))))))))

|#
