# vertico-truncate
Judicious truncation for long candidates in [vertico](https://github.com/minad/vertico) completion.

Left truncates lines in two situations:

1. Longer consult recentf files, which would otherwise move the
 suffix over (e.g. marginalia data), are left-truncated to avoid
    this.
2. `consult-line` and `consult-*grep` matches on long lines are
   left-truncated to ensure the first match (from grep or
   completion style) remains visible.  You may consider increasing
   `consult-grep-max-columns` (and, potentially, altering
   `consult-ripgrep-args` --max-columns flag if that affects you).
   Note that VERY long lines (above a few thousand chars) can have
   a negative performance impact in Emacs.
   
Others may be considered.
