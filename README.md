# vertico-truncate
Judicious truncation for long candidates in [vertico](https://github.com/minad/vertico) completion.

Left-truncates completion lines in vertico for ~two~ one situations:

1. Longer files, which would otherwise move the
 suffix over (e.g. marginalia data), are left-truncated to avoid
    this.
2. **Update**: this part is no longer functioning and the solution it uses
   is too hacky to continue supporting.  Please open an issue over on
   consult if you want this functionality.  `consult-line` and
   `consult-*grep` matches on long lines are left-truncated to ensure
   the first match (from grep or the completion style) remains
   visible.  You may also consider increasing
   `consult-grep-max-columns` (and, potentially, altering
   `consult-ripgrep-args` --max-columns flag if that affects you).
   Note that VERY long lines (above a few thousand chars) can have a
   negative performance impact in Emacs.
   
Others may be considered.

## Installation/usage

Install using straight, use-package with load-path, etc.  To enable, simply arrange to call `(vertico-truncate-mode 1)` in your init.
