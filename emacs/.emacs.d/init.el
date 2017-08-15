;; Added by Package.el.  This must come before configurations of
;; installed packages.  Don't delete this line.  If you don't want it,
;; just comment it out by adding a semicolon to the start of the line.
;; You may delete these explanatory comments.
(require 'package)
;; remove the load path for nix profiles
;; todo: fix woman
(eval-after-load 'woman '(error "fix the path from /nix/*-emacs-*/..site-start.el first"))

(require 'seq)
(setq load-path
      (seq-difference load-path (mapcar (lambda (x) (concat x "/share/emacs/site-lisp/"))
                               (split-string (or (getenv "NIX_PROFILES") "")))))

(package-initialize 'noactivate)
(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(custom-safe-themes
   (quote
    ("d677ef584c6dfc0697901a44b885cc18e206f05114c8a3b7fde674fce6180879" "a8245b7cc985a0610d71f9852e9f2767ad1b852c2bdea6f4aadc12cce9c4d6d0" "8aebf25556399b58091e533e455dd50a6a9cba958cc4ebb0aab175863c25b9a4" default)))
 )

(setq org-modules '(org-bbdb org-bibtex org-docview org-gnus org-habit
                    org-info org-irc org-mhe org-rmail org-w3m))
(org-babel-load-file "~/dotfiles/emacs/emacs.org")

