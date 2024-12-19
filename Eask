(package "comment-dwim-2"
         "1.5.0"
         "An all-in-one comment command to rule them all")

(website-url "https://github.com/remyferre/comment-dwim-2")
(keywords "convenience" "tools")

(package-file "comment-dwim-2.el")

;; Can be run with "eask run script SCRIPT"
(script "lint" (concat
                "eask lint package comment-dwim-2.el && "
                "eask lint checkdoc comment-dwim-2.el && "
                "eask lint elint comment-dwim-2.el && "
                "eask lint elisp-lint comment-dwim-2.el && "
                "eask lint indent comment-dwim-2.el && "
                "eask lint keywords && "
                "eask lint declare comment-dwim-2.el && "
                "eask lint regexps comment-dwim-2.el && "
                "eask compile comment-dwim-2.el ; "
                "eask clean autoloads -- ; eask clean elc --"))
(script "test" "eask test ert test/comment-dwim-2-test.el")

(source "gnu")
(source "melpa")

(depends-on "emacs" "28.1")
