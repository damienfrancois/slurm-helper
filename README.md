slurm-helper
============

Bunch of helper files for the Slurm resource manager

Bash completion
---------------

The Bash completion script offers <TAB> completion for Slurm commands. 

At present the following Slurm commands are considered
* `scontrol`
* `sreport`

__Installation__

Simply source the script in your `.bashrc` or `.profile`

__Known issues__

Keyword arguments are not auto-completed beyond the first one.

Vim syntax file
---------------

The Vim syntax file renders the Slurm batch submission scripts easier to read and to spot errors in the submission options. 

As submission scripts are indeed shell scripts, and all Slurm options are actually Shell comments, it can be difficult to spot errors in the options. 

This syntax file allows vim to understand the Slurm option and highlight them accordingly. Whenever possible, the syntax rules check the validity of the options and put in a special color what is not recognized as a valid option, or valid parameters values. 

__Installation__

Under Linux or MacOS, simply copy the file in the directory

    .vim/after/syntax/sh/

or whatever shell other than ``sh`` you prefer. 

The syntax file is then read and applied on a Shell script after the usual syntax file has been processed. 

__Known issues__

* Some regex needed to validate options or parameter values are not exactly correct, but should work in most cases. 
* Any new option unknown to the syntax file will be spotted as an error. 

Nano syntax file
-----------------

The Nano syntax file highlights SBATCH comments in a font distinct from other comments. 

__Installation__

Under Linux or MacOS, simply copy the file in your nano directory, e.g.

    .nano.d

and add

    include ~/.nano.d/slurm.nanorc

to your `.nanorc` file

__Known issues__

* Very basic syntax highlighting without any syntax checking, contrarily to the
  Vim version.

Emacs syntax file
-----------------

The Emacs syntax file highlights `SBATCH` comments in a font distinct from other
comments:

![Example of slurm-mode highlighting](http://damienfrancois.github.com/slurm-helper/slurm-mode.png)

__Installation__

Under Linux or MacOS, simply copy the `slurm-mode.el` file in your emacs load path, e.g.

    .emacs.d

and add

```lisp
(add-to-list 'load-path "~/.emacs.d/")

(require 'slurm-mode)
(add-hook 'sh-mode-hook 'turn-on-slurm-mode)
```

to your `.emacs` or `.emacs.d/init.el` file

__Known issues__

* Very basic syntax highlighting without any syntax checking (beyond arguments
  spelling), contrarily to the Vim version.

Emacs interface
---------------

`slurm.el` provides a User Interface to slurm within Emacs:

![Example of slurm.el interface](http://damienfrancois.github.com/slurm-helper/slurm_jobsList.png)

__Installation__

Simply copy the `slurm.el` file in your emacs load path, e.g.

    .emacs.d
    
and add the following snippet to your init file (`.emacs` or
`.emacs.d/init.el`):

```lisp
(add-to-list 'load-path "~/.emacs.d/")

(require 'slurm)
```

__Usage__

Just run `M-x slurm` to see a list of all SLURM jobs on the cluster. From there,
let `C-h m` guide you through the various key bindings allowing to manipulate
the different view:
- `j`: **j**obs list (default view)
- `p`: **p**artitions list
- `i`: cluster **i**nformation
