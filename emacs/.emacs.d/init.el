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
    ("8db4b03b9ae654d4a57804286eb3e332725c84d7cdab38463cb6b97d5762ad26" "d677ef584c6dfc0697901a44b885cc18e206f05114c8a3b7fde674fce6180879" "a8245b7cc985a0610d71f9852e9f2767ad1b852c2bdea6f4aadc12cce9c4d6d0" "8aebf25556399b58091e533e455dd50a6a9cba958cc4ebb0aab175863c25b9a4" default)))
 '(notmuch-saved-searches
   (quote
    ((:name "unread" :query "tag:unread" :key "u")
     (:name "flagged" :query "tag:flagged" :key "f")
     (:name "sent" :query "tag:sent" :key "t")
     (:name "drafts" :query "tag:draft" :key "d")
     (:name "all mail" :query "*" :key "a")
     (:name "inbox" :query "tag:inbox"))))
 '(safe-local-variable-values
   (quote
    ((eval c-set-offset
           (quote inlambda)
           0)
     (eval c-set-offset
           (quote arglist-cont-nonempty)
           (quote
            (c-lineup-gcc-asm-reg c-lineup-arglist)))
     (eval c-set-offset
           (quote arglist-close)
           0)
     (eval c-set-offset
           (quote arglist-intro)
           (quote ++))
     (eval c-set-offset
           (quote case-label)
           0)
     (eval c-set-offset
           (quote statement-case-open)
           0)
     (eval c-set-offset
           (quote access-label)
           (quote -))
     (eval c-set-offset
           (quote substatement-open)
           0)
     (eval c-set-offset
           (quote arglist-cont-nonempty)
           (quote +))
     (eval c-set-offset
           (quote arglist-cont)
           0)
     (eval c-set-offset
           (quote arglist-intro)
           (quote +))
     (eval c-set-offset
           (quote inline-open)
           0)
     (eval c-set-offset
           (quote defun-open)
           0)
     (eval c-set-offset
           (quote innamespace)
           0)
     (indicate-empty-lines . t)))))

(setq org-modules '(org-bbdb org-bibtex org-docview org-gnus org-habit
			     org-info org-irc org-mhe org-rmail org-w3m))
(setq max-lisp-eval-depth 10000)
 (setq max-specpdl-size 13000)
(org-babel-load-file "~/dotfiles/emacs/emacs.org")
;(add-to-list 'custom-theme-load-path "~/tmp/emacs-color-theme-solarized")
;; (defun set-solarized-theme (frame theme)
;;   (set-frame-parameter frame 'background-mode theme)
;;   (set-terminal-parameter frame 'background-mode theme)
;;   (load-theme 'solarized)
;;   ;; transparent background
;;   (when (not (display-graphic-p)) (set-face-background 'default "unspecified-bg" frame)))
;; (add-hook 'after-make-frame-functions
;;           (lambda (frame)
;;             (let ((mode (if (display-graphic-p frame) 'light 'dark)))
;;               (set-solarized-theme frame mode) 
;;             )))
(xterm-mouse-mode 1)
(define-key local-function-key-map "\033[73;5~" [(control return)])
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(evil-goggles-change-face ((t (:inherit diff-removed))))
 '(evil-goggles-delete-face ((t (:inherit diff-removed))))
 '(evil-goggles-paste-face ((t (:inherit diff-added))))
 '(evil-goggles-undo-redo-add-face ((t (:inherit diff-added))))
 '(evil-goggles-undo-redo-change-face ((t (:inherit diff-changed))))
 '(evil-goggles-undo-redo-remove-face ((t (:inherit diff-removed))))
 '(evil-goggles-yank-face ((t (:inherit diff-changed)))))


