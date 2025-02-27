#|
    Boxer
    Copyright 1985-2022 Andrea A. diSessa and the Estate of Edward H. Lay

    Portions of this code may be copyright 1982-1985 Massachusetts Institute of Technology. Those portions may be
    used for any purpose, including commercial ones, providing that notice of MIT copyright is retained.

    Licensed under the 3-Clause BSD license. You may not use this file except in compliance with this license.

    https://opensource.org/licenses/BSD-3-Clause


                                         +-Data--+
                This file is part of the | BOXER | system
                                         +-------+


 This file contains the bootstrap script for running the tests and starting up the UI. Can be loaded
 directory in lispworks.

      (load #P"./src/bootstrap.lisp")

|#
(require "asdf")
(ql:quickload :drakma)
(ql:quickload :html-entities)
(ql:quickload :cl-freetype2)


;; TODO fix this to preserve the windows logical drive
(defvar *boxer-project-dir* (make-pathname :directory (butlast (pathname-directory *load-truename*))))

(setf asdf:*central-registry*
               (list* '*default-pathname-defaults*
                      *boxer-project-dir*
                      #+win32 #P"Z:/code/boxer-sunrise/"
                asdf:*central-registry*))

(setf *features* (cons :opengl *features*))
(setf *features* (cons :freetype-fonts *features*))
(asdf:load-system :boxer-sunrise-core)
