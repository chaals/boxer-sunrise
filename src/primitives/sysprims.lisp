;;;;  -*- Mode:LISP; Syntax:Common-Lisp; Package:BOXER; -*-
;;;;
;;;;      Boxer
;;;;      Copyright 1985-2022 Andrea A. diSessa and the Estate of Edward H. Lay
;;;;
;;;;      Portions of this code may be copyright 1982-1985 Massachusetts Institute of Technology. Those portions may be
;;;;      used for any purpose, including commercial ones, providing that notice of MIT copyright is retained.
;;;;
;;;;      Licensed under the 3-Clause BSD license. You may not use this file except in compliance with this license.
;;;;
;;;;      https://opensource.org/licenses/BSD-3-Clause
;;;;
;;;;
;;;;                                        +-Data--+
;;;;               This file is part of the | BOXER | system
;;;;                                        +-------+
;;;;
;;;;
;;;;
;;;;
;;;;           This file contains primitives for altering
;;;;           system level parameters for the Boxer System
;;;;
;;;;
;;;;  Modification History (most recent at the top)
;;;;
;;;;   4/10/14 com-show-font-info, bu::show-font-info
;;;;   2/17/12 added bu::name-link-boxes
;;;;   1/11/10 added bu::report-crash
;;;;   1/03/10 added bu::boxer-window-{width,height}
;;;;  11/17/08 added bu::update-display-during-eval, defboxer-preference now handles keyword option correctly
;;;;   8/05/08 changed all pref name discrimination from #+/-lwwin to #+/-capi
;;;;  10/06/05 added penerase-color-from-bit-array, temporarily
;;;;   7/23/04 added mail-inbox-file, removed max-viewable-message-size & draw=icon-options
;;;;  10/31/03 removed #+carbon-compat bu::immediate-sprite-drawing
;;;;   9/08/03 new pref for #+carbon-compat bu::immediate-sprite-drawing
;;;;   5/16/03 draw-icon-options (temporary) for #+lwwin
;;;;   4/21/03 merged current LW and MCL files
;;;;   9/08/02 removed fullscreen-window and added maximize-window to do the same job
;;;;           in order to be UC free compliant
;;;;   5/24/01 removed zoom-pause added popup-mouse-documentation
;;;;   5/10/01 changed pref categories to shorter names so the folder tabs
;;;;           in the preference dialog will line up better
;;;;   5/05/01 changed defboxer-preference macro to preserve documentation line breaks
;;;;   2/17/01 merged current LW and MCL files
;;;;   9/10/00 query-for-unknown-mime-type added to network-settings
;;;;   5/28/00 more LW changes to the defboxer-preference macro
;;;;   5/14/00 initial LW changes
;;;;   6/13/99 added fullscreen-window
;;;;   5/12/99 made Andy suggested changes to documentation wording
;;;;   4/26/99 added max-viewable-message-size to network settings
;;;;   4/20/99 added warn-about-outlink-ports
;;;;   9/14/98 removed disable-box-resizing preference
;;;;   9/02/98 changed documentation for zoom-pause to inform about 0 value option
;;;;   9/02/98 Start logging changes: source = boxer version 2.3beta
;;;;

(in-package :boxer)



;;; This is basically defboxer-primitive with some bookeeping info
;;; INITIAL-VALUE is a list composed of a LISP part (the CAR) and
;;;               a BOXER part (the CADR)
;;; DOCUMENTATION is also broken into 2 parts.  The CAR is a type keyword
;;; and the CDR should be acceptable to make-box (a list of lists)

(defvar *boxer-preferences-list* nil)

(defvar *preference-read-handlers* nil)
(defvar *preference-write-handlers* nil)

(eval-when (compile load eval)
           (defmacro defboxer-preference (name args
                                               (initial-value-spec . documentation)
                                               &body body)
             (let ((file-reader-name (intern (symbol-format nil "~A-FILE-READER" name) 'boxer))
                   (file-writer-name (intern (symbol-format nil "~A-FILE-WRITER" name) 'boxer))
                   ;; these are used by the preferences dialog on the mac
                   #+(or mcl lispworks)
                   (dialog-item-action-name (intern (symbol-format nil "~A-DI-ACTION"
                                                                   name) 'boxer))
                   #+(or mcl lispworks)
                   (queued-pref-name (intern (symbol-format nil "~A-Q-FUNCTION"
                                                            name) 'boxer))
                   #+(or mcl lispworks)
                   (dialog-item-doc-name (intern (symbol-format nil "~A-DI-DOC"
                                                                name) 'boxer))
                   (variable (car initial-value-spec))
                   (value-type (cadr initial-value-spec)))
               `(progn
                 ;; first, stash away info that we will need later to setup the
                 ;; preferences menu box.
                 (unless (fast-memq ',name *boxer-preferences-list*)
                   (setq *boxer-preferences-list*
                         (append *boxer-preferences-list* (list ',name))))
                 ;; read/write handlers for prefs files
                 (let ((existing-r-entry (assoc ',name *preference-read-handlers*))
                       (existing-w-entry (assoc ',name *preference-write-handlers*)))
                   (if (null existing-r-entry)
                     (push (list ',name ',file-reader-name ',value-type)
                           *preference-read-handlers*)
                     ;; just bash the slots in the existing entry
                     (setf (cadr existing-r-entry)  ',file-reader-name
                           (caddr existing-r-entry) ',value-type))
                   (if (null existing-w-entry)
                     (push (list ',name ',file-writer-name ',value-type)
                           *preference-write-handlers*)
                     ;; just bash the slots in the existing entry
                     (setf (cadr existing-w-entry)  ',file-writer-name
                           (caddr existing-w-entry) ',value-type)))
                 ;; funcalled from handle-site-initializations (in site.lisp)
                 (defun ,file-reader-name (value-string)
                   (let ((new-value (coerce-config-value value-string ,value-type)))
                     (unless (or (null *site-initialization-verbosity*)
                                 (member :mcl-appgen *features*))
                       (format t "~%Initializing System Variable ~A to ~A"
                               ',variable new-value))
                     (setq ,variable new-value)))
                 (defun ,file-writer-name (filestream)
                   (format filestream "~A: ~A~%" ',name ,(cond ((eq value-type :boolean)
                                                                `(if ,variable "True" "False"))
                                                           (t variable))))
                 ;; used to generate a pref setting box with the current value
                 (setf (get ',name 'system-parameter-default-value)
                       #'(lambda () ,(caddr initial-value-spec)))
                 ;; documentation for the pref setting box
                 (unless (null ',documentation)
                   (setf (get ',name 'system-parameter-type) ',(car documentation))
                   (setf (get ',name 'system-parameter-documentation)
                         ',(cdr documentation)))
                 ;; hooks for autogenerate preferences dialog
                 #+(or mcl lispworks)
                 (defun ,queued-pref-name (,(pref-arg-name args))
                   . ,body)
                 #+(or mcl lispworks)
                 (defun ,dialog-item-action-name (di)
                   (let ((existing (fast-assq ',queued-pref-name
                                              *preference-dialog-change-list*))
                         #+lispworks
                         (value ,(ecase value-type
                                        (:boolean '(capi:button-selected di))
                                        (:number '(let ((ns (capi:text-input-pane-text di)))
                                                    (when (numberstring? ns)
                                                      (ignoring-number-read-errors
                                                       (read-from-string ns nil nil)))))
                                        (:string  '(capi:text-input-pane-text di))
                                        (:keyword '(capi:text-input-pane-text di))))
                         )
                     (cond ((not (null existing))
                            (setf (cdr existing) value))
                       (t (push (cons ',queued-pref-name value)
                                *preference-dialog-change-list*)))))
                 #+(or mcl lispworks)
                 (defun ,dialog-item-doc-name (di)
                   #+lispworks
                   (unless (eq di *preference-dialog-last-doc-item*)
                     (setf (capi:display-pane-text *current-documentation-dialog-item*)
                           ',(unpack-documentation (cdr documentation)))
                     (setq *preference-dialog-last-doc-item* di))
                   )
                 #+(or mcl lispworks)
                 (setf (get ',name 'system-parameter-pref-dialog-info)
                       (list ',variable ',(car documentation) ',value-type
                             ',dialog-item-action-name ',dialog-item-doc-name))
                 (boxer-eval::defboxer-primitive ,name ,args
                                                  ;; sort of flaky but don't want to have to specify separate args
                                                  ;; for the function and the body
                                                  (let ((,(pref-arg-name args)
                                                         ,(ecase value-type
                                                                 (:boolean `(boxer-eval::true? ,(pref-arg-name args)))
                                                                 (:number  (pref-arg-name args))
                                                                 (:string `(box-text-string ,(pref-arg-name args)))
                                                                 (:keyword `(intern-keyword (box-text-string ,(pref-arg-name args)))))))
                                                    . ,body)))))


           (defun pref-arg-name (arglist)
             (let ((guess (car arglist))) (cond ((listp guess) (cadr guess)) (t guess))))


           ;; doc's are a list of lists of strings
           #+(or mcl lispworks)
           (defun flatten-documentation (doc)
             (let ((return-string (make-array 64 :element-type 'standard-char
                                              :fill-pointer 0 :adjustable t)))
               (dolist (x doc)
                 (let* ((str (car x)) (end (length str)))
                   (do ((i 0 (1+& i))) ((>=& i end))
                     (vector-push-extend (char str i) return-string)))
                 (vector-push-extend #\space return-string))
               return-string))

           #+lispworks
           (defun unpack-documentation (doc)
             (with-collection
               (dolist (x doc)
                 (collect (car x)))))

) ;; eval-when

;;; Reading in Preferences Files....
;; basically the same as handle-site-initialization(s)
(defun handle-preference-initializations (pref-file)
  (with-open-file (s pref-file :direction :input)
    (loop
      (multiple-value-bind (valid? eof? keyword value)
                           (read-config-line s *keyword-buffer* *value-buffer*)
                           (cond (eof? (return))
                             (valid? (handle-preference-initialization
                                      (intern-in-bu-package keyword) value)))
                           (buffer-clear *keyword-buffer*)
                           (buffer-clear *value-buffer*)))))

(defun handle-preference-initialization (keyword value)
  (let ((handler-entry (assoc keyword *preference-read-handlers*)))
    (if (null handler-entry)
      (warn "~A is an obsolete pref. Save boxer prefs again to eliminate further warnings" keyword)
      (funcall (cadr handler-entry) value))))

;;; Writing out Preferences Files
(defun write-preferences (&optional (file #+(and unix (not lispworks)) "~/.boxerrc"
                                          #+mcl
                                          (default-mac-pref-file-name)
                                          #+lispworks
                                          (default-lw-pref-file-name)))
  (with-open-file (fs file :direction :output :if-exists :supersede)
    (format fs "# Boxer Preferences File Created on ~A~%"
            (boxer::rfc822-date-time))
    (dolist (pref *boxer-preferences-list*)
      (let ((write-handler (assoc pref *preference-write-handlers*)))
        (unless (null write-handler)
          (funcall (cadr write-handler) fs))))))

(boxer-eval::defboxer-primitive bu::save-preferences ()
                                (write-preferences)
                                boxer-eval::*novalue*)



;; Might as well zero out the list upon load to make development a bit easier
(eval-when (load) (setq *boxer-preferences-list* nil))

;;;; Printer Preferences

(defboxer-preference bu::printing-precision ((boxer-eval::numberize new-precision))
  ((*decimal-print-precision* :number *decimal-print-precision*)
   #+capi results #-capi result-appearance
   ("How many numerals should appear after")
   ("the decimal point in decimal numbers ?"))
  (cond ((and (integerp new-precision)
              (>=& new-precision 0))
         (set-decimal-printing-precision new-precision))
    (t (set-decimal-printing-precision nil)))
  boxer-eval::*novalue*)


(defboxer-preference bu::print-fractions (true-or-false)
  ((*print-rationals* :boolean (boxer-eval::boxer-boolean *print-rationals*))
   #+capi results #-capi result-appearance
   ("Should fractional numbers (e.g., 1/2) appear as ")
   ("fractions (1/2), rather than decimals (0.5) ?"))
  (setq *print-rationals* true-or-false)
  boxer-eval::*novalue*)


(defboxer-preference bu::preserve-empty-lines-in-build (true-or-false)
  ((*interpolate-empty-rows-too?* :boolean
                                  (boxer-eval::boxer-boolean *interpolate-empty-rows-too?*))
   #+capi results #-capi result-appearance
   ("Should empty lines in boxes referred to via @'s")
   ("in BUILD templates be preserved ? "))
  (setq *interpolate-empty-rows-too?* true-or-false)
  boxer-eval::*novalue*)

;;;; Stepper and Evaluator preferences...

(defboxer-preference bu::step-wait-for-key-press (true-or-false)
  ((boxer-eval::*step-wait-for-key-press* :boolean
                                          (boxer-eval::boxer-boolean boxer-eval::*step-wait-for-key-press*))
   #+capi evaluator #-capi evaluator-settings
   ("Should the Stepper wait for a key press ")
   ("before going on to the next step ?")
   ("(The Stepper shows Boxer execution one step at a time.)"))
  (setq boxer-eval::*step-wait-for-key-press* true-or-false)
  boxer-eval::*novalue*)

(defboxer-preference bu::step-time ((boxer-eval::numberize seconds))
  ((boxer-eval::*step-sleep-time* :number boxer-eval::*step-sleep-time*)
   #+capi evaluator #-capi evaluator-settings
   ("How many seconds should the Stepper pause between steps")
   ("(The Stepper shows Boxer execution one step at a time.)"))
  (setq boxer-eval::*step-sleep-time* seconds)
  boxer-eval::*novalue*)


(defboxer-preference bu::evaluator-help (true-or-false)
  ((*evaluator-helpful* :boolean (boxer-eval::boxer-boolean *evaluator-helpful*))
   #+capi evaluator #-capi evaluator-settings
   ("Should the Evaluator print \"helpful\" messages")
   ("when it detects style problems ?")
   ("(E.g., if you port to the output of a primitive)"))
  (setq *evaluator-helpful* true-or-false)
  boxer-eval::*novalue*)

(defboxer-preference bu::primitive-shadow-warnings (true-or-false)
  ((boxer-eval::*warn-about-primitive-shadowing* :boolean
                                                 (boxer-eval::boxer-boolean boxer-eval::*warn-about-primitive-shadowing*))
   #+capi evaluator #-capi evaluator-settings
   ("Should you get a warning if you redefine a Boxer primitive ?"))
  (setq boxer-eval::*warn-about-primitive-shadowing* true-or-false)
  boxer-eval::*novalue*)

(defboxer-preference bu::update-display-during-eval (true-or-false)
  ((*repaint-during-eval?* :keyword
                           (boxer-eval::boxer-boolean boxer-eval::*warn-about-primitive-shadowing*))
   #+capi evaluator #-capi evaluator-settings
   ("Should the screen be repainted during eval ? Valid entries are ALWAYS, NEVER and CHANGED-GRAPHICS"))
  (setq *repaint-during-eval?* true-or-false)
  boxer-eval::*novalue*)



;;; Graphics Preferences

(defboxer-preference bu::make-transparent-graphics-boxes (true-or-false)
  ((*default-graphics-box-transparency* :boolean
                                        (boxer-eval::boxer-boolean *default-graphics-box-transparency*))
   #+capi graphics #-capi graphics-settings
   ("Should newly made graphics boxes be transparent ?"))
  (setq *default-graphics-box-transparency* true-or-false)
  boxer-eval::*novalue*)

(defboxer-preference bu::include-sprite-in-new-graphics (true-or-false)
  ((*include-sprite-box-in-new-graphics?* :boolean
                                          (boxer-eval::boxer-boolean *include-sprite-box-in-new-graphics?*))
   #+capi graphics #-capi graphics-settings
   ("Should newly made graphics boxes include a sprite ?"))
  (setq *include-sprite-box-in-new-graphics?* true-or-false)
  boxer-eval::*novalue*)

(defboxer-preference bu::name-new-sprites (true-or-false)
  ((*name-new-sprites?* :boolean (boxer-eval::boxer-boolean *name-new-sprites?*))
   #+capi graphics #-capi graphics-settings
   ("Should the cursor be moved into")
   ("the name row of new sprite boxes ?"))
  (setq *name-new-sprites?* true-or-false)
  boxer-eval::*novalue*)

(defboxer-preference bu::make-diet-sprites (true-or-false)
  ((*new-sprites-should-be-diet-sprites?* :boolean
                                          (boxer-eval::boxer-boolean *new-sprites-should-be-diet-sprites?*))
   #+capi graphics #-capi graphics-settings
   ("Should newly made sprite boxes include fewer")
   ("visible attributes to save memory ?"))
  (cond ((not (null true-or-false))
         (setq *new-sprites-should-be-diet-sprites?* t
               *graphics-interface-boxes-in-box* :default
               *graphics-interface-boxes-in-closet* :default))
    (t
     (setq *new-sprites-should-be-diet-sprites?* nil
           *graphics-interface-boxes-in-box*
           '(x-position y-position heading)
           *graphics-interface-boxes-in-closet*
           '(shape shown? home-position sprite-size
                   pen pen-width type-font pen-color))))
  boxer-eval::*novalue*)

(defboxer-preference bu::penerase-color-from-bit-array (true-or-false)
  ((*check-bit-array-color* :boolean (boxer-eval::boxer-boolean *check-bit-array-color*))
   #+capi graphics #-capi graphics-settings
   ("Should the backing store of a frozen box be")
   ("checked for the penerase color if one exists ?"))
  (setq *check-bit-array-color* true-or-false)
  boxer-eval::*novalue*)

(defboxer-preference bu::show-border-type-labels (true-or-false)
  ((*show-border-type-labels* :boolean (boxer-eval::boxer-boolean *show-border-type-labels*))
   #+capi editor #-capi editor-settings
   ("Should the type label (e.g., doit, data) of boxes be shown ?"))
  (setq *show-border-type-labels* true-or-false)
  (force-repaint)
  boxer-eval::*novalue*)

(defboxer-preference bu::show-empty-name-rows (true-or-false)
  ((*show-empty-name-rows* :boolean (boxer-eval::boxer-boolean *show-empty-name-rows*))
   #+capi editor #-capi editor-settings
   ("Should we show name rows that are empty?"))
  (setq *show-empty-name-rows* true-or-false)
  (force-repaint)
  boxer-eval::*novalue*)

(defboxer-preference bu::smooth-scrolling (true-or-false)
  ((*smooth-scrolling?* :boolean (boxer-eval::boxer-boolean *smooth-scrolling?*))
   #+capi editor #-capi editor-settings
   ("Should scrolling be one pixel at a time ?")
   ("(This may be turned off for slow machines)"))
  (setq *smooth-scrolling?* true-or-false)
  (force-repaint)
  boxer-eval::*novalue*)

(defboxer-preference bu::global-hotspot-controls (true-or-false)
  ((*global-hotspot-control?* :boolean
                              (boxer-eval::boxer-boolean *global-hotspot-control?*))
   #+capi editor #-capi editor-settings
   ("Should turning a hotspot off or on affect all hotspots ?"))
  (setq *global-hotspot-control?* true-or-false)
  boxer-eval::*novalue*)

;; sgithens 2021-03-28 Removing this for now as we are consolidating keyboards for all 3 platforms. This may or may not
;;                     be useful again in the future.
;;
;; (defboxer-preference bu::input-device-names (machine-type)
;;   ((*current-input-device-platform* :keyword
;;                                     (make-box
;;                                      `((,*current-input-device-platform*))))
;;    #+capi editor #-capi editor-settings
;;    ("Which set of names should be used to refer to ")
;;    ("special (control) keys or mouse actions ?")
;;    ("(Different platforms may use different names.)"))
;;   (let ((canonicalized-name (intern (string-upcase machine-type)
;;                                     (find-package 'keyword))))
;;     (if (fast-memq canonicalized-name *defined-input-device-platforms*)
;;       (make-input-devices canonicalized-name)
;;       (boxer-eval::primitive-signal-error :preference
;;                                           "The machine-type, " machine-type
;;                                           ", does not have a defined set of input devices"))
;;     boxer-eval::*novalue*))

(defun switch-use-mouse2021 (use-mouse2021)
  "Takes a boolean deciding whether or not to use the new 2021 Mouse Click Events.
  This can be called during runtime to toggle between the two versions of mouse clicks.

  This function will:
    - Update the value of bw::*use-mouse2021*
    - Call use-mouse2021-keybindings to update the keybindings for various click/up/down items"
  (setq bw::*use-mouse2021* use-mouse2021)
  ;; Note, in the future we may want to change the platform with `make-input-devices`
  (use-mouse2021-keybindings use-mouse2021))

(defboxer-preference bu::use-mouse2021 (true-or-false)
  ((bw::*use-mouse2021* :boolean
                        (boxer-eval::boxer-boolean bw::*use-mouse2021*))
   #+capi editor #-capi editor-settings
   ("Should we use the new 2021 Mouse Click events?"))
  (switch-use-mouse2021 true-or-false)
  boxer-eval::*novalue*)


;; added 9/08/02
(defboxer-preference bu::maximize-window (true-or-false)
  ((bw::*fullscreen-window-p* :boolean
                              (boxer-eval::boxer-boolean bw::*fullscreen-window-p*))
   #+capi editor #-capi editor-settings
   ("Should the boxer window occupy the entire screen ?"))
  (setq bw::*fullscreen-window-p* true-or-false)
  boxer-eval::*novalue*)

(defboxer-preference bu::boxer-window-width ((boxer-eval::numberize w))
  ((bw::*starting-window-width* :number bw::*starting-window-width*)
   #+capi editor #-capi editor-settings
   ("The initial width of the Boxer window, 0 lets the computer decide"))
  (setq bw::*starting-window-width* w)
  boxer-eval::*novalue*)

(defboxer-preference bu::boxer-window-height ((boxer-eval::numberize w))
  ((bw::*starting-window-height* :number bw::*starting-window-height*)
   #+capi editor #-capi editor-settings
   ("The initial height of the Boxer window, 0 lets the computer decide"))
  (setq bw::*starting-window-height* w)
  boxer-eval::*novalue*)

(defboxer-preference bu::boxer-window-show-toolbar (true-or-false)
  ((bw::*boxer-window-show-toolbar-p* :boolean
                              (boxer-eval::boxer-boolean bw::*boxer-window-show-toolbar-p*))
   #+capi editor #-capi editor-settings
   ("Display the toolbar on the boxer editor window?"))
  (setq bw::*boxer-window-show-toolbar-p* true-or-false)
  (capi::apply-in-pane-process *boxer-pane* #'bw::update-visible-editor-panes)
  boxer-eval::*novalue*)

(defboxer-preference bu::boxer-window-show-statusbar (true-or-false)
  ((bw::*boxer-window-show-statusbar-p* :boolean
                              (boxer-eval::boxer-boolean bw::*boxer-window-show-statusbar-p*))
   #+capi editor #-capi editor-settings
   ("Display the toolbar on the boxer editor window?"))
  (setq bw::*boxer-window-show-statusbar-p* true-or-false)
  (capi::apply-in-pane-process *boxer-pane* #'bw::update-visible-editor-panes)
  boxer-eval::*novalue*)

;; This should be changed to :choice after the :choice pref is implemented
#+(and (not opengl) capi) ; dont offer until it works...
(defboxer-preference bu::popup-mouse-documentation (true-or-false)
  ((*popup-mouse-documentation?* :boolean
                                 (boxer-eval::boxer-boolean
                                  *popup-mouse-documentation?*))
   #+capi editor #-capi editor-settings
   ("Should mouse documentation popup after a short delay ?"))
  (setq *popup-mouse-documentation* true-or-false)
  boxer-eval::*novalue*)

(defboxer-preference bu::report-crash (true-or-false)
  ((bw::*report-crash* :boolean
                       (boxer-eval::boxer-boolean bw::*report-crash*))
   #+capi editor #-capi editor-settings
   ("Should lisp errors be logged ?"))
  (setq bw::*report-crash* true-or-false)
  boxer-eval::*novalue*)

;;;; (Postscript) Printer Preferences (mostly unix based)

#+(and unix (not macosx))
(defboxer-preference bu::printer-name (printer-name)
  ((*ps-postscript-printer* :string (make-box `((,*ps-postscript-printer*))))
   #+capi printer #-capi printer-settings
   ("The name of the printer used for")
   ("Postscript output"))
  (let ((newname  printer-name))
    ;; need some sort of consistency checking on the name here
    (setq *ps-postscript-printer* newname)
    boxer-eval::*novalue*))

#+(and unix (not macosx))
(defboxer-preference bu::printer-host (machine-name)
  ((*ps-postscript-printer-host* :String (make-box `((,*ps-postscript-printer-host*))))
   #+capi printer #-capi printer-settings
   ("The name of the machine attached to the")
   ("printer used for Postscript output"))
  (let ((newname machine-name))
    ;; need some sort of consistency checking on the name here
    (setq *ps-postscript-printer-host* newname)
    boxer-eval::*novalue*))

#+(and unix (not macosx))
(defboxer-preference bu::printer-filename (filename)
  ((*ps-file* :string (make-box `((,*ps-file*))))
   #+capi printer #-capi printer-settings
   ("The name of the file used by Com-Print-Screen-To-File")
   ("for Postscript output"))
  (let ((newname filename))
    ;; need some sort of consistency checking on the name here
    (setq *ps-file* newname)
    boxer-eval::*novalue*))

;;;; Serial Line Preferences

#+(and unix (not macosx))
(defboxer-preference bu::newline-after-serial-writes (true-or-false)
  ((*add-newline-to-serial-writes* :boolean
                                   (boxer-eval::boxer-boolean *add-newline-to-serial-writes*))
   #+capi communication #-capi communication-settings
   ("Should extra Carriage Returns be added")
   ("at the end of each Serial-Write ? "))
  (setq *add-newline-to-serial-writes* true-or-false)
  boxer-eval::*novalue*)

#+(and unix (not macosx))
(defboxer-preference bu::serial-read-base ((boxer-eval::numberize radix))
  ((*serial-read-base* :number *serial-read-base*)
   #+capi communication #-capi communication-settings
   ("The radix that the serial line will")
   ("use to read in n (possible) numbers"))
  (setq *serial-read-base* radix)
  boxer-eval::*novalue*)


;; File system prefs

(defboxer-preference bu::terse-file-status (true-or-false)
  ((*terse-file-status* :boolean
                        (boxer-eval::boxer-boolean *terse-file-status*))
   #+capi Files #-capi File-System-Settings
   ("Should file names use abbreviated form (as opposed to ")
   ("full pathnames) in the status line ?"))
  (setq *terse-file-status* true-or-false)
  boxer-eval::*novalue*)

(defboxer-preference bu::backup-file-suffix (suffix)
  ((*file-backup-suffix* :string (make-box `((,*file-backup-suffix*))))
   #+capi Files #-capi File-System-Settings
   ("Which character string should be appended to previous ")
   ("file version when Boxer saves ?"))
  (setq *file-backup-suffix* suffix)
  boxer-eval::*novalue*)

(defboxer-preference bu::name-link-boxes (true-or-false)
  ((*name-link-boxes* :boolean
                      (boxer-eval::boxer-boolean *name-link-boxes*))
   #+capi Files #-capi File-System-Settings
   ("Should box links to non boxer files be created with the same name as the file"))
  (setq *name-link-boxes* true-or-false)
  boxer-eval::*novalue*)

(defboxer-preference bu::warn-about-outlink-ports (true-or-false)
  ((*warn-about-outlink-ports* :boolean
                               (boxer-eval::boxer-boolean *warn-about-outlink-ports*))
   #+capi Files #-capi File-System-Settings
   ("Should you receive a warning when trying to save a ")
   ("file with ports that link outside the file ?"))
  (setq *warn-about-outlink-ports* true-or-false)
  boxer-eval::*novalue*)

;;; Network stuff

;; sgithens 2021-03-08 Removing these network email preferences as email support is currently broken
;;                     and we aren't sure whether we will include this functionality going forward.
;;
;; (defboxer-preference bu::user-mail-address (address)
;;   ((boxnet::*user-mail-address* :string
;;                                 (make-box `((,boxnet::*user-mail-address*))))
;;    #+capi network #-capi network-settings
;;    ("What Internet address should identify you in various network dealings ?"))
;;   (let* ((newname address)
;;          (@pos (position #\@ newname)))
;;     ;; need some sort of consistency checking on the name here
;;     (if (null @pos)
;;       (boxer-eval::primitive-signal-error :preferences-error
;;                                           newname
;;                                           " Does not look like a valid address")
;;       (let ((user (subseq newname 0 @pos)) (host (subseq newname (1+ @pos))))
;;         (setq boxnet::*user-mail-address* newname
;;               boxnet::*pop-user* user
;;               boxnet::*pop-host* host)))
;;     boxer-eval::*novalue*))

;; (defboxer-preference bu::mail-relay-host (host)
;;   ((boxnet::*smtp-relay-host* :string (make-box `((,boxnet::*smtp-relay-host*))))
;;    #+capi network #-capi network-settings
;;    ("What computer should be responsible for ")
;;    ("relaying mail to the Internet ?"))
;;   (let ((newname host))
;;     ;; need some sort of consistency checking on the name here
;;     (setq boxnet::*smtp-relay-host* newname)
;;     boxer-eval::*novalue*))

;; ;; should have a hook to access the MIME type dialog

;; (defboxer-preference bu::query-for-unkown-mime-type (true-or-false)
;;   ((boxnet::*query-for-unknown-mime-type* :boolean
;;                                           (boxer-eval::boxer-boolean boxnet::*query-for-unknown-mime-type*))
;;    #+capi network #-capi network-settings
;;    ("Should a dialog popup if an unknown")
;;    ("MIME (mail attachment) type is encountered ?"))
;;   (setq boxnet::*query-for-unknown-mime-type* true-or-false)
;;   boxer-eval::*novalue*)

;; (defboxer-preference bu::mail-inbox-file (filename)
;;   ((boxnet::*inbox-pathname* :string (make-box `((,boxnet::*inbox-pathname*))))
;;    #+capi network #-capi network-settings
;;    ("Which File should new mail be placed in"))
;;   (let ((newpath filename))
;;     ;; should reality check here (at least directory should exist)
;;     (setq boxnet::*inbox-pathname* newpath)
;;     boxer-eval::*novalue*))

;;;; Putting it all together....

;;; we may want to structure this by conceptual grouping later...
;;; for now, we make box for each entry, the box contains the
;;; documentation box (if there is one) and a line to execute
;;; under it

(defun make-preferences-box ()
  (let ((prefs-box (make-box '(("Boxer Preferences..."))))
        (subgroup-box-alist nil))
    (flet ((make-pref-box (fun initial-value doc)
                          (if (null doc)
                            (make-box (list (list fun
                                                  (cond ((virtual-copy? initial-value)
                                                         (top-level-print-vc
                                                          initial-value))
                                                    (t initial-value)))))
                            (make-box (list (list (make-box doc))
                                            (list fun
                                                  (cond ((virtual-copy? initial-value)
                                                         (top-level-print-vc
                                                          initial-value))
                                                    (t initial-value)))))))
           (subgroup-box (preference)
                         (let ((subgroup (get preference 'system-parameter-type)))
                           (or (cdr (assoc subgroup subgroup-box-alist))
                               (let ((new (make-box '(()) 'data-box
                                                    (string-capitalize
                                                     (symbol-name subgroup)))))
                                 (setf (slot-value new 'first-inferior-row) nil)
                                 (setq subgroup-box-alist
                                       (acons subgroup new subgroup-box-alist))
                                 (shrink new)
                                 (append-row prefs-box (make-row (list new)))
                                 new)))))
          (dolist (pref *boxer-preferences-list*)
            (let ((pbox (make-pref-box
                         pref
                         (funcall (get pref 'system-parameter-default-value))
                         (get pref 'system-parameter-documentation)))
                  (subgroup (subgroup-box pref)))
              (shrink pbox)
              (append-row subgroup (make-row (list pbox))))))
    prefs-box))

(defboxer-command com-make-preferences-box ()
  "Insert the Preferences Box at the Cursor"
  (reset-region)
  (reset-editor-numeric-arg)
  (insert-cha *point* (make-preferences-box))
  boxer-eval::*novalue*)

(boxer-eval::defboxer-primitive bu::system-preferences ()
                                (virtual-copy (make-preferences-box)))

;;; use this after the site file has been edited
(boxer-eval::defboxer-primitive bu::reconfigure-system ()
                                (handle-site-initializations)
                                boxer-eval::*novalue*)

;; Temporarily, or perhaps permanently removing this while fonts are being
;; reworked and simplified.
;; (defboxer-command com-show-font-info ()
;;   "Display font information"
;;   (reset-region)
;;   (reset-editor-numeric-arg)
;;   (insert-cha *point* (make-box (mapcar #'list (bw::capogi-fonts-info))))
;;   boxer-eval::*novalue*)

;; (boxer-eval::defboxer-primitive bu::show-font-info ()
;;   (virtual-copy (make-box (mapcar #'list (bw::capogi-fonts-info)))))

;;; should specify all available slots, punt for now
(defun empty-configuration-box () (make-box '(())))

(boxer-eval::defboxer-primitive bu::configuration-info ()
  (let* ((confile (merge-pathnames *default-configuration-file-name*
                                    *default-site-directory*))
          (conbox (if (probe-file confile)
                    (read-text-file-internal confile)
                    (empty-configuration-box))))
    (shrink conbox)
    (make-vc (list (list "Edit" "the" "following" "box:")
                    (list "Write-Text-File" conbox
                          (make-box `((,(namestring confile)))))
                    (list "You" "need" "to" "write" "out" "your" "changes"
                          "by" "evaluating" "the" "above" "line")
                    (list "and" "then" "evaluate" "the" "next" "line"
                          "to" "make" "the" "changes")
                    (list "Reconfigure-System")))))

(boxer-eval:defboxer-primitive bu::toggle-fonts ()
  "A command for toggling between capi cfnt fonts and freetype fonts
   until we're done with the transition."
                               (if (member :freetype-fonts *features*)
                                 (setf *features* (remove :freetype-fonts *features*))
                                 (setf *features* (cons :freetype-fonts *features*)))
                               boxer-eval::*novalue*)
