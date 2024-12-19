# 1.5.0
* `comment-dwim-2` now uses lexical binding
* `org-comment-dwim-2` is obsolete as `comment-dwim-2` now supports `org-mode` by default
* The package has been rewritten to better follow Elisp coding conventions. Public variables and functions have been renamed as follows:
    * `comment-dwim-2--inline-comment-behavior` -> `comment-dwim-2-inline-comment-behavior`
    * `cd2/comment-or-uncomment-region` -> `comment-dwim-2-comment-or-uncomment-region`
    * `cd2/comment-or-uncomment-lines` -> `comment-dwim-2-comment-or-uncomment-lines`
    * `cd2/comment-or-uncomment-lines-or-region-dwim` -> `comment-dwim-2-comment-or-uncomment-lines-or-region-dwim`
    * `cd2/region-command` -> `comment-dwim-2-region-function`
* `comment-dwim-2-inline-comment-behavior` and `comment-dwim-2-region-function` can now also be set via `M-x customize`
