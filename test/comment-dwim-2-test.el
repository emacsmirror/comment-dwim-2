;;; comment-dwim-2-test.el --- Tests for comment-dwim-2  -*- lexical-binding: t; -*-

(add-to-list 'load-path "..")
(require 'comment-dwim-2)

;;;; Helpers

(defmacro comment-dwim-2--test-setup (buffer-content &rest body)
  (declare (indent 1))
  `(save-excursion
     (with-temp-buffer
       (switch-to-buffer (current-buffer))
       (c-mode)
       (transient-mark-mode)
       (font-lock-mode)
       (insert ,buffer-content)
       (font-lock-ensure)
       (setq-default comment-column 32)
       (setq-default indent-tabs-mode t)
       (setq-default tab-width 8)
       (setq kill-ring ())
       (setq last-command nil)
       (goto-char (point-min))
       (setq comment-dwim-2-inline-comment-behavior 'kill-comment)
       (setq comment-dwim-2-region-function 'comment-dwim-2-comment-or-uncomment-lines-or-region-dwim)
       ,@body)))

(defmacro comment-dwim-2--test-setup-with-reindent (buffer-content &rest body)
  (declare (indent 1))
  `(comment-dwim-2--test-setup ,buffer-content
     (setq comment-dwim-2-inline-comment-behavior 'reindent-comment)
     ,@body))

(defun should-buffer (str)
  (should (string-equal str (buffer-substring-no-properties (point-min) (point-max)))))

(advice-add #'comment-dwim-2 :around (lambda (orig-fun &rest args)
                                       (font-lock-ensure)
                                       (apply orig-fun args)
                                       (setq last-command 'comment-dwim-2)))

;;;; Unit tests

;;; Private functions

(ert-deftest comment-dwim-2--test-line-contains-comment-p ()
  (comment-dwim-2--test-setup "Foo //"        (should (comment-dwim-2--line-contains-comment-p)))
  (comment-dwim-2--test-setup "Foo // Bar"    (should (comment-dwim-2--line-contains-comment-p)))
  (comment-dwim-2--test-setup "// Foo"        (should (comment-dwim-2--line-contains-comment-p)))
  (comment-dwim-2--test-setup "Foo /**/"      (should (comment-dwim-2--line-contains-comment-p)))
  (comment-dwim-2--test-setup "Foo /* Bar */" (should (comment-dwim-2--line-contains-comment-p)))
  (comment-dwim-2--test-setup "/* Foo */"     (should (comment-dwim-2--line-contains-comment-p)))
  (comment-dwim-2--test-setup "Foo"           (should (not (comment-dwim-2--line-contains-comment-p)))))

(ert-deftest comment-dwim-2--test-fully-commented-line-p ()
  (comment-dwim-2--test-setup "// Foo"         (should (comment-dwim-2--fully-commented-line-p)))
  (comment-dwim-2--test-setup "/* Foo */"      (should (comment-dwim-2--fully-commented-line-p)))
  (comment-dwim-2--test-setup " 	// Foo"    (should (comment-dwim-2--fully-commented-line-p)))
  (comment-dwim-2--test-setup " 	/* Foo */" (should (comment-dwim-2--fully-commented-line-p)))
  (comment-dwim-2--test-setup "Bar // Foo"     (should (not (comment-dwim-2--fully-commented-line-p))))
  (comment-dwim-2--test-setup "/* Foo */ Bar"  (should (not (comment-dwim-2--fully-commented-line-p))))
  (comment-dwim-2--test-setup "Bar"            (should (not (comment-dwim-2--fully-commented-line-p)))))

(ert-deftest comment-dwim-2--test-line-ends-with-multiline-comment-p ()
  (comment-dwim-2--test-setup "\"Foo\""
    (should (not (comment-dwim-2--line-ends-with-multiline-string-p))))
  (comment-dwim-2--test-setup "\"Foo\"\n\"Bar\""
    (should (not (comment-dwim-2--line-ends-with-multiline-string-p)))
    (forward-line)
    (should (not (comment-dwim-2--line-ends-with-multiline-string-p))))
  (comment-dwim-2--test-setup "\"Foo\\\nBar\""
    (should (comment-dwim-2--line-ends-with-multiline-string-p))
    (forward-line)
    (should (not (comment-dwim-2--line-ends-with-multiline-string-p))))
  (comment-dwim-2--test-setup " \"Foo\\\nBar\""
    (should (comment-dwim-2--line-ends-with-multiline-string-p))))

;;; comment-dwim-2 tests

;; comment-dwim-2-region-function

(ert-deftest comment-dwim-2--test-comment-or-uncomment-lines-or-region-dwim ()
  (comment-dwim-2--test-setup "First line\nSecond line"
    (should (eq comment-dwim-2-region-function 'comment-dwim-2-comment-or-uncomment-lines-or-region-dwim))
    (set-mark 6) (goto-char 15)
    (comment-dwim-2) (should-buffer "/* First line */\n/* Second line */")
    (comment-dwim-2) (should-buffer "First line\nSecond line")
    (lisp-mode)
    (set-mark 6) (goto-char 15)
    (comment-dwim-2) (should-buffer "First;;  line\n;; Sec\nond line")))

(ert-deftest comment-dwim-2--test-comment-or-uncomment-region ()
  (comment-dwim-2--test-setup "First line\nSecond line"
    (setq comment-dwim-2-region-function 'comment-dwim-2-comment-or-uncomment-region)
    (set-mark 6) (goto-char 15)
    (comment-dwim-2) (should-buffer "First/*  line */\n/* Sec */ond line")
    (comment-dwim-2) (should-buffer "First line\nSecond line")))

(ert-deftest comment-dwim-2--test-comment-or-uncomment-lines ()
  (comment-dwim-2--test-setup "First line\nSecond line"
    (setq comment-dwim-2-region-function 'comment-dwim-2-comment-or-uncomment-lines)
    (set-mark 6) (goto-char 15)
    (comment-dwim-2) (should-buffer "/* First line */\n/* Second line */")
    (comment-dwim-2) (should-buffer "First line\nSecond line")
    (lisp-mode)
    (set-mark 6) (goto-char 15)
    (comment-dwim-2) (should-buffer ";; First line\n;; Second line")))

(ert-deftest comment-dwim-2--test-comment-region-that-spans-one-line ()
  (comment-dwim-2--test-setup ""
    (dolist (region-function
             '(comment-dwim-2-comment-or-uncomment-lines-or-region-dwim
               comment-dwim-2-comment-or-uncomment-region
               comment-dwim-2-comment-or-uncomment-lines))
      (progn
        (setq comment-dwim-2-region-function region-function)
        (kill-region (point-min) (point-max)) (insert "This is a line")
        (set-mark 3) (goto-char 10)
        (comment-dwim-2) (should-buffer "Th/* is is a */ line")))))

;; comment-dwim-2-inline-comment-behavior == 'kill-comment

(ert-deftest comment-dwim-2--test-uncommented-line ()
  (comment-dwim-2--test-setup "Foo\n"
    (comment-dwim-2) (should-buffer "/* Foo */\n")
    (comment-dwim-2) (should-buffer "Foo				/*  */\n")
    (comment-dwim-2) (should-buffer "Foo\n")))

(ert-deftest comment-dwim-2--test-empty-line ()
  (comment-dwim-2--test-setup ""
    (comment-dwim-2) (should-buffer "/*  */")
    (comment-dwim-2) (should-buffer "")))

(ert-deftest comment-dwim-2--test-commented-line ()
  (comment-dwim-2--test-setup "// Foo\n"
    (comment-dwim-2) (should-buffer "Foo\n")
    (comment-dwim-2) (should-buffer "/* Foo */\n")
    (comment-dwim-2) (should-buffer "Foo				/*  */\n")
    (comment-dwim-2) (should-buffer "Foo\n")))

(ert-deftest comment-dwim-2--test-commented-line-2 ()
  (comment-dwim-2--test-setup "Foo // Bar\n"
    (comment-dwim-2) (should-buffer "/* Foo // Bar */\n")
    (comment-dwim-2) (should-buffer "Foo\n")
    (comment-dwim-2) (should-buffer "/* Foo */\n")
    (comment-dwim-2) (should-buffer "Foo				/*  */\n")
    (comment-dwim-2) (should-buffer "Foo\n")))

(ert-deftest comment-dwim-2--test-commented-line-3 ()
  (comment-dwim-2--test-setup "// Foo // Bar\n"
    (comment-dwim-2) (should-buffer "Foo // Bar\n")
    (comment-dwim-2) (should-buffer "Foo\n")
    (comment-dwim-2) (should-buffer "/* Foo */\n")
    (comment-dwim-2) (should-buffer "Foo				/*  */\n")
    (comment-dwim-2) (should-buffer "Foo\n")))

(ert-deftest comment-dwim-2--test-multiline-string ()
  (comment-dwim-2--test-setup "\"Foo\\\nBar\"\n"
    (forward-char 3)
    (comment-dwim-2) (should-buffer "/* \"Foo\\ */\nBar\"\n")
    (comment-dwim-2) (should-buffer "\"Foo\\\nBar\"\n"))
  (comment-dwim-2--test-setup "\"Foo\\\nBar\"\n"
    (forward-line)
    (comment-dwim-2) (should-buffer "\"Foo\\\n/* Bar\" */\n")
    (comment-dwim-2) (should-buffer "\"Foo\\\nBar\"				/*  */\n")))

(ert-deftest comment-dwim-2--test-nested-commented-line ()
  (comment-dwim-2--test-setup "// // // Foo\n"
    (comment-dwim-2) (should-buffer "// // Foo\n")
    (comment-dwim-2) (should-buffer "// Foo\n")
    (comment-dwim-2) (should-buffer "Foo				/*  */\n")))

(ert-deftest comment-dwim-2--test-prefix-argument ()
  (comment-dwim-2--test-setup "Foo // Bar\n"
    (comment-dwim-2 4) (should-buffer "Foo				// Bar\n")))

;; comment-dwim-2-inline-comment-behavior == 'reindent-comment

(ert-deftest comment-dwim-2--test-uncommented-line-with-reindent ()
  (comment-dwim-2--test-setup-with-reindent "Foo\n"
    (comment-dwim-2) (should-buffer "/* Foo */\n")
    (comment-dwim-2) (should-buffer "Foo				/*  */\n")
    (comment-dwim-2) (should-buffer "Foo				/*  */\n")))

(ert-deftest comment-dwim-2--test-empty-line-with-reindent ()
  (comment-dwim-2--test-setup-with-reindent ""
    (comment-dwim-2) (should-buffer "/*  */")
    (comment-dwim-2) (should-buffer "")))

(ert-deftest comment-dwim-2--test-commented-line-with-reindent ()
  (comment-dwim-2--test-setup-with-reindent "// Foo\n"
    (comment-dwim-2) (should-buffer "Foo\n")
    (comment-dwim-2) (should-buffer "/* Foo */\n")
    (comment-dwim-2) (should-buffer "Foo				/*  */\n")
    (comment-dwim-2) (should-buffer "Foo				/*  */\n")))

(ert-deftest comment-dwim-2--test-commented-line-2-with-reindent ()
  (comment-dwim-2--test-setup-with-reindent "Foo // Bar\n"
    (comment-dwim-2) (should-buffer "/* Foo // Bar */\n")
    (comment-dwim-2) (should-buffer "Foo				// Bar\n")
    (comment-dwim-2) (should-buffer "Foo				// Bar\n")))

(ert-deftest comment-dwim-2--test-commented-line-3-with-reindent ()
  (comment-dwim-2--test-setup-with-reindent "// Foo // Bar\n"
    (comment-dwim-2) (should-buffer "Foo // Bar\n")
    (comment-dwim-2) (should-buffer "Foo				// Bar\n")
    (comment-dwim-2) (should-buffer "Foo				// Bar\n")))

(ert-deftest comment-dwim-2--test-multiline-string-with-reindent ()
  (comment-dwim-2--test-setup-with-reindent "\"Foo\\\nBar\"\n"
    (forward-char 3)
    (comment-dwim-2) (should-buffer "/* \"Foo\\ */\nBar\"\n")
    (comment-dwim-2) (should-buffer "\"Foo\\\nBar\"\n"))
  (comment-dwim-2--test-setup-with-reindent "\"Foo\\\nBar\"\n"
    (forward-line)
    (comment-dwim-2) (should-buffer "\"Foo\\\n/* Bar\" */\n")
    (comment-dwim-2) (should-buffer "\"Foo\\\nBar\"				/*  */\n")))

(ert-deftest comment-dwim-2--test-nested-commented-line-with-reindent ()
  (comment-dwim-2--test-setup-with-reindent "// // // Foo\n"
    (comment-dwim-2) (should-buffer "// // Foo\n")
    (comment-dwim-2) (should-buffer "// Foo\n")
    (comment-dwim-2) (should-buffer "Foo				/*  */\n")))

(ert-deftest comment-dwim-2--test-prefix-argument-with-reindent ()
  (comment-dwim-2--test-setup-with-reindent "Foo // Bar\n"
    (comment-dwim-2 4) (should-buffer "Foo\n")))

;; comment-dwim-2-inline-comment-behavior == 'wrong-value

(ert-deftest comment-dwim-2--test-uncommented-line-with-wrong-value ()
  (comment-dwim-2--test-setup "Foo\n"
    (setq comment-dwim-2-inline-comment-behavior 'wrong-value)
    (comment-dwim-2) (should-buffer "/* Foo */\n")
    (comment-dwim-2) (should-buffer "Foo				/*  */\n")
    (should-error (comment-dwim-2))))

(ert-deftest comment-dwim-2--test-prefix-argument-with-wrong-value ()
  (comment-dwim-2--test-setup "Foo // Bar\n"
    (setq comment-dwim-2-inline-comment-behavior 'wrong-value)
    (should-error (comment-dwim-2 4))))

;; org-mode support

(ert-deftest comment-dwim-2--test-org-mode ()
  (comment-dwim-2--test-setup "
* Header
#+BEGIN_SRC C
  Foo
#+END_SRC"
    (org-mode)
    (forward-char 1)
    (comment-dwim-2) (should-buffer "
* COMMENT Header
#+BEGIN_SRC C
  Foo
#+END_SRC")
    (comment-dwim-2) (should-buffer "
* Header
#+BEGIN_SRC C
  Foo
#+END_SRC")
    (forward-char 27)
    (comment-dwim-2) (should-buffer "
* Header
#+BEGIN_SRC C
  /* Foo */
#+END_SRC")
    (comment-dwim-2) (should-buffer "
* Header
#+BEGIN_SRC C
  Foo				/*  */
#+END_SRC")
    (comment-dwim-2) (should-buffer "
* Header
#+BEGIN_SRC C
  Foo
#+END_SRC")))

;;; comment-dwim-2-test.el ends here
