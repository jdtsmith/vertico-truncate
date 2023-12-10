;;; vertico-truncate --- Smart truncation of long vertico candidates -*- lexical-binding: t -*-

;; Copyright (C) 2023  J.D. Smith

;; Author: J.D. Smith
;; Homepage: https://github.com/jdtsmith/vertico-truncate
;; Package-Requires: (vertico)
;; Version: 0.0.1
;; Keywords: convenience
;; Prefix: vertico-truncate
;; Separator: -

;; This is free software: you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation, either version 3 of the
;; License, or (at your option) any later version.

;; This is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.


;;; Commentary:

;; vertico-truncate patches vertico to perform judicious
;; left-truncation of candidates in certain situations.  This occurs
;; in a couple of scenarios:

;; 1. Longer consult recentf files, which would otherwise move the
;;    suffix over (e.g. marginalia data), are left-truncated to avoid
;;    this.
;;
;; 2. consult-line and consult-*grep matches on long lines are
;;    left-truncated to ensure the first match (from grep or
;;    completion style) remains visible.  You may consider increasing
;;    `consult-grep-max-columns' (and, potentially, altering
;;    `consult-ripgrep-args' --max-columns flag if that affects you).
;;    Note that VERY long lines (above a few thousand chars) can have
;;    a negative performance impact in Emacs.
;;
;; Truncated candidates are prepended with '…'.
;;
;; To enable, simply arrange to call (vertico-truncate-mode 1) in your
;; init.
;; 

;;; Code:
(require 'cl-lib)
(require 'vertico)

(defvar vertico-truncate-extra-faces '(consult-highlight-match)
  "Extra faces indicating matches.
These face are set in advance of deferred highlighting.")

(defun vertico-truncate--wrap-highlight (hl)
  "Return a new highlighter which records the range of first match highlight.
The returned function calls highlighter function HL, recording a
cons of a range (beg . end) for the first new face found (if
any).  This range is recorded at the end of the candidate itself
in a text property 'vertico-truncate-hl-column."
  (lambda (list)
    (let* (rng
	   (old-face-starts ; do not copy full cand list, store face ranges
	    (cl-loop for old in list for rng = nil collect
		     (cl-loop for rng being the intervals of old property 'face
			      for face = (get-text-property (car rng) 'face old)
			      if face collect (cons (car rng) face))))
	   (hl-list (funcall hl list)))
      (cl-loop for new in hl-list for ofs in old-face-starts for len = (length new) do
	       (cl-loop for rng being the intervals of new property 'face
			for face = (get-text-property (car rng) 'face new)
			for old-face = (alist-get (car rng) ofs)
			if (or (seq-intersection (ensure-list face)
						 vertico-truncate-extra-faces)
			       (and face (not (equal old-face face))))
			do (put-text-property (1- len) len ; at to end to prevent trim
					      'vertico-truncate-hl-column rng new)
			(cl-return)))
      hl-list)))

(defun vertico-truncate--hl-wrapper (var-alist)
  "Wrap vertico's defered highlight function and return its VAR-ALIST.
The higlight function is among the elements of the alist returned
from `vertico--recompute'.  Wrap it with
`vertico-truncate--wrap-highlight', which sets a custom text
property at the first match location."
  (when-let ((rec (assq 'vertico--highlight var-alist))
	     ((functionp (cdr rec)))
	     ((not (eq (cdr rec) #'identity))))
    (setcdr rec (vertico-truncate--wrap-highlight (cdr rec))))
  var-alist)

(defun vertico-truncate--trim-candidates (args)
  "Left truncate consult recentf and long-line candidates among ARGS."
  (let* ((cand (car args))
	 (len (length cand)))
    (cond
     ;; left-truncate recent files in consult-buffer
     ((or (eq (vertico--metadata-get 'category) 'file)
	  (when-let ((type (get-text-property 0 'multi-category cand)))
	    (eq (car-safe type) 'file)))
      (let* ((suffix-len (length (nth 2 args)))
	     (ww (vertico--window-width))
	     (w (max 30 (- ww suffix-len))))
	(when (> len w)
	  (setcar args
		  (concat "…" (truncate-string-to-width cand len (- len w)))))))

     ;; left-truncate long lines in consult-line/grep/etc. to show match
     ((memq (setq cat (vertico--metadata-get 'category))
	    '(consult-grep consult-location))
      (let* ((prefix-len (length (nth 1 args)))
	     (ww  (vertico--window-width))
	     (avail (- ww prefix-len)) fhc)
	(when (and
	       (> len avail) 		; a long candidate
	       (setq fhc (get-text-property (1- len) 'vertico-truncate-hl-column cand))
	       (or (> (cdr fhc) avail)	       ; match end falls off
		   (> (car fhc) (- avail 5)))) ; match starts too close to end
	  (let* ((offset (if (eq cat 'consult-grep) ; consult-grep leaves line prefix 
			     (1+ (next-single-property-change 0 'face cand))))
		 (pad (min 20 (/ ww 4))) ; some left-padding for the match
		 (from-end (- len avail))
		 (from-start (- (car fhc) pad -1))
		 (start (max (or offset 0) (min from-end from-start))))
	    (setcar args
		    (concat (if offset (substring cand 0 offset))
			    "…" (truncate-string-to-width cand len start)))))))))
  args)

(define-minor-mode vertico-truncate-mode
  "Minor mode which truncates certain long consult candidates in vertico."
  :global t
  :group 'vertico
  (cond
   (vertico-truncate-mode
    (advice-add #'vertico--recompute :filter-return #'vertico-truncate--hl-wrapper)
    (advice-add #'vertico--format-candidate :filter-args #'vertico-truncate--trim-candidates))
   (t
    (advice-remove #'vertico--recompute #'vertico-truncate--hl-wrapper)
    (advice-remove #'vertico--format-candidate #'vertico-truncate--trim-candidates))))

(provide 'vertico-truncate)
;;; vertico-truncate.el ends here

