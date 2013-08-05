;;; slurm-mode.el --- Edit SLURM job submission scripts

;; Copyright (C) 2012, Damien François  <damien.francois@uclouvain.be>
;;                     François Févotte <fevotte@gmail.com>

;; Derived from fic-mode.el by Trey Jackson

;; This file is NOT part of Emacs.

;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation; either version 2 of
;; the License, or (at your option) any later version.
;;
;; This program is distributed in the hope that it will be
;; useful, but WITHOUT ANY WARRANTY; without even the implied
;; warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
;; PURPOSE.  See the GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public
;; License along with this program; if not, write to the Free
;; Software Foundation, Inc., 59 Temple Place, Suite 330, Boston,
;; MA 02111-1307 USA


;;; Commentary:

;; If you make improvements to this code or have suggestions, please do not hesitate to fork the
;; repository or submit bug reports on github. The repository is at:
;;
;;     https://github.com/damienfrancois/slurm-helper

;;; Code:

;;;###autoload
(defcustom slurm-directives-face 'slurm-directives
  "Face name to use for SBATCH directives in SLURM job submission scripts."
  :group 'slurm
  :type 'face)

;;;###autoload
(defface slurm-directives nil
  "Face to use for SBATCH directives in SLURM job submission scripts."
  :group 'slurm)
(copy-face 'font-lock-type-face 'slurm-directives)

(defvar slurm-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "C-c C-d") 'slurm-insert-directive)
    map)
  "Keymap for `slurm-mode'.")

(defconst slurm-keywords
  '("account"         "acctg-freq"        "begin"           "checkpoint"   "checkpoint-dir"
    "comment"         "constraint"        "constraint"      "contiguous"   "cores-per-socket"
    "cpu-bind"        "cpus-per-task"     "dependency"      "distribution" "error"
    "exclude"         "exclusive"         "extra-node-info" "get-user-env" "get-user-env"
    "gid"             "hint"              "immediate"       "input"        "job-id"
    "job-name"        "licences"          "mail-type"       "mail-user"    "mem"
    "mem-bind"        "mem-per-cpu"       "mincores"        "mincpus"      "minsockets"
    "minthreads"      "network"           "nice"            "nice"         "no-kill"
    "no-requeue"      "nodefile"          "nodelist"        "nodes"        "ntasks"
    "ntasks-per-core" "ntasks-per-socket" "ntasks-per-node" "open-mode"    "output"
    "overcommit"      "partition"         "propagate"       "propagate"    "quiet"
    "requeue"         "reservation"       "share"           "signal"       "socket-per-node"
    "tasks-per-node"  "threads-per-core"  "time"            "tmp"          "uid"
    "wckey"           "workdir"           "wrap")
  "List of allowed SBATCH keywords in SLURM submission scripts.")

(defconst slurm-keywords-re
  (concat "--" (regexp-opt slurm-keywords) "\\b")
  "Regular expression matching SBATCH keywords in a SLURM job
submission script.")

(defun slurm-insert-directive (keyword)
  "Interactively insert a SLURM directive of the form:

#SBATCH --keyword
"
  (interactive
   (list (completing-read "Keyword: "
                          slurm-keywords nil t)))
  (insert (concat "#SBATCH --" keyword " ")))

(defun slurm-search-directive-1 (limit)
  "Search for the next #SBATCH directive.

Returns:
- nil    if no SBATCH directives are found
- error  if the following SBATCH directive is malformed
- an integer corresponding to the point position of the next SBATCH
   directive beginning if it is found and well-formed."

  ;; Find #SBATCH directive
  (when (re-search-forward "^\\s *#SBATCH\\b" limit t)
    (let ((beg (match-beginning 0)))

      ;; Find SBATCH keyword
      (if (re-search-forward (concat "\\=\\s +" slurm-keywords-re "\\s *") limit t)
          ;; Try to move point to the end of the argument
          (progn
            (cond
             ;; No argument: end of line or beginning of comment
             ((looking-at "\\(\\s<\\|$\\)")
              t)
             ;; Quoted argument
             ((looking-at "\\s\"")
              (forward-sexp))
             ;; Unquoted argument
             (t
              (re-search-forward "\\=[^[:space:]#\n]+" limit t)))
            beg)
        'error))))

(defun slurm-search-directive (limit)
  (let (beg)
    (save-match-data
      (while (eq (setq beg (slurm-search-directive-1 limit)) 'error) t))
    (unless (null beg)
      (set-match-data (list beg (point)))
      t)))

;;;###autoload
(define-minor-mode slurm-mode
  "Edit SLURM job submission scripts.

When slurm-mode is on, SBATCH directives are highlighted.
This mode also provides a command to insert new SBATCH directives :
  \\<slurm-mode-map>
  \\[slurm-insert-directive] - `slurm-insert-directive'
"
  :lighter " slurm"
  :group 'slurm
  :keymap slurm-mode-map
  (let ((kwlist `(("^\\s *\\(#SBATCH[^#\n]*\\)\\s *\\(#.*\\)?$" 1 font-lock-warning-face t)
                  (slurm-search-directive 0 slurm-directives-face t))))
    (if slurm-mode
        (font-lock-add-keywords nil kwlist)
      (font-lock-remove-keywords nil kwlist))))

;;;###autoload
(defun turn-on-slurm-mode ()
  "Turn slurm-mode on if SBATCH directives are found in the script."
  (interactive)
  (save-excursion
    (goto-char (point-min))
    (when (slurm-search-directive (point-max))
      (slurm-mode 1))))

(provide 'slurm-mode)

;; slurm-mode.el ends here