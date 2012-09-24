;;; slurm-mode.el --- Show SBATCH options in special font
;;--------------------------------------------------------------------
;;
;; Copyright (C) 2012, Damien François <damien.francois@uclouvain.be>
;;
;; This file is NOT part of Emacs.
;;
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
;;
;; To use, save slurm-mode.el to a directory in your load-path.
;;
;; (require 'slurm-mode)
;; (add-hook 'sh-mode-hook 'turn-on-slurm-mode)
;;
;; Derived from fic-mode.el by Trey Jackson

(defcustom font-lock-slurm-face font-lock-type-face
  "Face name to use for SBATCH directives in SLURM submission scripts."
  :group 'slurm-mode
  :type 'face)

(defvar slurm-search-list-re
  (concat
   "^\\s *\\(#SBATCH\\s +--"
   (regexp-opt
    '("account"         "acctg-freq"        "begin"           "checkpoint"   "checkpoint-dir"
      "comment"         "constraint"        "constraint"      "contiguous"   "cores-per-socket"
      "cpu-bind"        "cpus-per-task"     "dependency"      "distribution" "error"
      "exclude"         "exclusive"         "extra-node-info" "get-user-env" "get-user-env"
      "gid"             "hint"              "immediate"       "input"        "job-id"
      "job-name"        "licences"          "mail-type"       "mail-user"    "mem"
      "mem-bind"        "mem-per-cpu"       "mincores"        "mincpus"      "minsockets"
      "minthreads"      "network"           "nice"            "nice"         "no-kill"
      "no-requeue"      "nodefile"          "nodelist"        "nodes"        "ntasks"
      "ntasks-per-core" "ntasks-per-socket" "ntasls-per-node" "open-mode"    "output"
      "overcommit"      "partition"         "propagate"       "propagate"    "quiet"
      "requeue"         "reservation"       "share"           "signal"       "socket-per-node"
      "tasks-per-node"  "threads-per-core"  "time"            "tmp"          "uid"
      "wckey"           "workdir"           "wrap"))
   "\\s +.*\\)$")
  "Regular expression matching SBATCH directives in a SLURM job submission script.")

;;;###autoload
(define-minor-mode slurm-mode
  "Highlight SBATCH directives in a SLURM job submission script."
  :lighter " slurm"
  :group 'slurm-mode
  (let ((kwlist `((,slurm-search-list-re 1 font-lock-slurm-face t))))
    (if slurm-mode
        (font-lock-add-keywords nil kwlist)
      (font-lock-remove-keywords nil kwlist))))

(defun turn-on-slurm-mode ()
  "Turn slurm-mode on."
  (interactive)
  (save-excursion
    (goto-char (point-min))
    (when (re-search-forward slurm-search-list-re nil t)
      (slurm-mode 1))))

(provide 'slurm-mode)
