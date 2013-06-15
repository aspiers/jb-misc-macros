;;; jb-misc-macros.el --- Miscellaneous macros

;; Filename: jb-misc-macros.el
;; Description: Miscellaneous macros
;; Author: Joe Bloggs <vapniks@yahoo.com>
;; Maintainer: Joe Bloggs <vapniks@yahoo.com>
;; Copyleft (Ↄ) 2013, Joe Bloggs, all rites reversed.
;; Created: 2013-06-05 01:38:24
;; Version: 0.1
;; Last-Updated: 2013-06-05 01:38:24
;;           By: Joe Bloggs
;; URL: https://github.com/vapniks/jb-misc-macros
;; Keywords: lisp
;; Compatibility: GNU Emacs 24.3.1
;; Package-Requires: ((macro-utils "1.0"))
;;
;; Features that might be required by this library:
;;
;; macro-utils.el
;;

;;; This file is NOT part of GNU Emacs

;;; License
;;
;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program; see the file COPYING.
;; If not, see <http://www.gnu.org/licenses/>.

;;; Commentary: 
;;
;; Bitcoin donations gratefully accepted: 1AoGev8FTwVVspNZxHuu8LMztAwxdzRndZ
;;
;; This library contains miscellaneous macros that I use in my projects, or that
;; I thought might be useful.

;;; Examples:
;;
;; Prompt the user for a free keybinding:
;; (untilnext (read-key-sequence "Enter a key: ")
;;            (read-key-sequence "That key is already bound to a command. Try again: ")
;;            (lambda (x) (not (key-binding x))))

;; Keep a track of the number of prompts
;; (untilnext (read-number "What is 1+1? Attempt 1: ")
;;            (prog1 (read-number  (concat "Wrong! Try again. Attempt " (number-to-string num) ": "))
;;              (setq num (1+ num)))
;;            (lambda (x) (= x 2))
;;            (num 1))


;;; Installation:
;;
;; Put jb-misc-macros.el in a directory in your load-path, e.g. ~/.emacs.d/
;; You can add a directory to your load-path with the following line in ~/.emacs
;; (add-to-list 'load-path (expand-file-name "~/elisp"))
;; where ~/elisp is the directory you want to add 
;; (you don't need to do this for ~/.emacs.d - it's added by default).
;;
;; Add the following to your ~/.emacs startup file.
;;
;; (require 'jb-misc-macros)

;;; Change log:
;;	
;; 2013/06/05
;;      * First released.
;; 

;;; Acknowledgements:
;;
;; Lars Brinkhoof for macro-utils.el, Paul Graham for his book "On Lisp"
;;

;;; TODO
;;
;; Macro that works like apply-partially but allowing partial application of args in any position.
;;

;;; Require
(require 'macro-utils)

;;; Code:

(defmacro untilnext (initform nextform &optional testfunc &rest bindings)
  "Evaluate INITFORM followed by NEXTFORM repeatedly. Stop when one of them returns non-nil, and returning that value.
If TESTFUNC is supplied it should be a function that takes a single argument (the results of evaluating INITFORM or NEXTFORM),
and will be used as the stopping criterion. In this case evaluation will stop when TESTFUNC returns non-nil, but the
return value of the macro will still be the return value of INITFORM or NEXTFORM.
If BINDINGS are supplied then these will be placed in a let form wrapping the code, thus allowing for some persistence of state
between successive evaluations of NEXTFORM."
  (once-only (initform)
             (let ((retval (gensym)))
               `(let* (,@bindings ,retval)
                  (or (and ,testfunc
                           (or (and (funcall ,testfunc ,initform) ,initform)
                               (while (not (funcall ,testfunc (setq ,retval ,nextform))))
                               ,retval))
                      ,initform
                      (and 
                       (while (not (setq ,retval ,nextform)))
                       ,retval))))))

;; This might be better as an inline function.
(defmacro list-subset (indices list)
  "Return elements of LIST corresponding to INDICES."
  `(mapcar (lambda (i) (nth i ,list)) ,indices))

(defun number-list (start end &optional length)
  "Return a sequential list of numbers from START to END.
If END is nil and LENGTH is provided then return a list from START to (1- (+ START LENGTH))."
  (if end
      (loop for i from start to end collect i)
    (assert length)
    (loop for i from start to (1- (+ start length)) collect i)))

;; This might be better as a function but I wanted to practice writing macros.
;; Also this way we can use gensyms to minimize the number of variables bound in the let
;; form surrounding the evaluation of FORMS.
(defmacro* read-key-menu (prompts forms &optional startstr endstr keys)
  "Prompt the user for a key and return the results of evaluating the corresponding form in the list FORMS.
If KEYS is supplied then it should be a list (of the same length as PROMPTS & FORMS) of keys to be prompted for.
Otherwise the lowercase letters of the alphabet will be used.

The prompt string for `read-key-sequence' will be formed from PROMPTS, KEYS and the optional STARTSTR and ENDSTR in
the following way:

STARTSTR
K1) PROMPT1
K2) PROMPT2
...
KN) PROMPT3
ENDSTR

Where K1-KN are key descriptions of the keys in KEYS, and PROMPT1-PROMPTN are the corresponding prompt strings in the
list PROMPTS.

The macro arguments will be evaluated once before expanding the macro."
  (setq prompts (eval prompts) forms (eval forms) startstr (eval startstr) endstr (eval endstr))
  (assert (= (length prompts) (length forms)))
  (setq keys (let* ((origkeys (eval keys))
                    (uniqkeys (remove 'nil origkeys))
                    (nextkey 47))
               (mapcar (lambda (key)
                         (or key (progn
                                   (setq nextkey (1+ nextkey))
                                   (while (member (char-to-string nextkey) uniqkeys)
                                     (setq nextkey (1+ nextkey)))
                                   (char-to-string nextkey))))
                       (nconc origkeys (make-list (- (length prompts) (length origkeys)) nil)))))
  (assert (= (length prompts) (length keys)))
  (with-gensyms (newprompts prompt retval keystrs maxlen)
                (let* ((keystrs (mapcar 'key-description keys))
                       (maxlen (loop for keystr in keystrs maximize (length keystr)))
                       (newprompts (mapcar* (lambda (k p)
                                              (let ((len (- maxlen (length k))))
                                                (concat k ") " (make-string len ? ) p)))
                                            keystrs prompts))
                       (prompt (concat (and startstr (concat startstr "\n"))
                                       (mapconcat 'identity newprompts "\n")
                                       "\nC-g) Quit"
                                       (and endstr (concat "\n" endstr)))))
                  `(let ((,retval 'again))
                     (while (eq ,retval 'again)
                       (let (key)
                         (while (not (or (member key ',keys) (equal key "")))
                           (setq key (read-key-sequence ,prompt nil t nil t)))
                         (if (equal key "")
                             (keyboard-quit)
                           (setq ,retval (eval (nth (position key ',keys :test 'equal) ',forms))))))
                     ,retval))))

(provide 'jb-misc-macros)

;; (magit-push)
;; (yaoddmuse-post "EmacsWiki" "jb-misc-macros.el" (buffer-name) (buffer-string) "update")

;;; jb-misc-macros.el ends here
