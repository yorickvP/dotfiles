;;; theme.el --- turn sanityinc-tomorrow into papercolor  -*- lexical-binding: t; -*
;; turn sanityinc-tomorrow into papercolor
;; https://github.com/NLKNguyen/papercolor-theme
(require 'cl-lib)

(defun merge-alists (alist1 alist2)
  "Merge two association lists, with alist2 taking precedence."
  (let ((result (copy-alist alist1)))
    (dolist (pair alist2 result)
      (let ((key (car pair))
            (value (cdr pair)))
        (if (assoc key result)
            (setf (cdr (assoc key result))
                  (if (listp value)
                      (merge-alists (cdr (assoc key result)) value)
                    value))
          (push pair result))))))

(defvar my-custom-tomorrow-colors
  '((day . ((background . "#eeeeee")
            (alt-background . "#e9e9e9e9e9e9")
            (current-line . "#e4e4e4")
            (foreground . "#3d3d3c")
            (red . "#d70000")
            (yellow . "#d75f00")
            (green . "#718c00")
            (navy . "#005f87")
            (olive . "#5f8700")
            (orange . "#d75f00")))))

(setq color-theme-sanityinc-tomorrow-colors
      (merge-alists color-theme-sanityinc-tomorrow-colors
                    my-custom-tomorrow-colors))
(color-theme-sanityinc-tomorrow--define-theme day)
(color-theme-sanityinc-tomorrow--define-theme night)

(defun unpackaged/customize-theme-faces (theme &rest faces)
  "Customize THEME with FACES.
Advises `enable-theme' with a function that customizes FACES when
THEME is enabled.  If THEME is already enabled, also applies
faces immediately.  Calls `custom-theme-set-faces', which see."
  (declare (indent defun))
  (when (member theme custom-enabled-themes)
    ;; Theme already enabled: apply faces now.
    (let ((custom--inhibit-theme-enable nil))
      (apply #'custom-theme-set-faces theme faces)))
  (let ((fn-name (intern (concat "unpackaged/enable-theme-advice-for-" (symbol-name theme)))))
    ;; Apply advice for next time theme is enabled.
    (fset fn-name
          (lambda (enabled-theme)
            (when (eq enabled-theme theme)
              (let ((custom--inhibit-theme-enable nil))
                (apply #'custom-theme-set-faces theme faces)))))
    (advice-remove #'enable-theme fn-name)
    (advice-add #'enable-theme :after fn-name)))

(defun +ygc (sym)
  (cdr (assoc sym (cdr (assoc 'day color-theme-sanityinc-tomorrow-colors)))))
(+ygc 'red)
(unpackaged/customize-theme-faces
 'sanityinc-tomorrow-day
 `(cursor ((t :background ,(+ygc 'navy) :foreground ,(+ygc 'background))))
 `(font-lock-keyword-face ((t :weight bold :foreground ,(+ygc 'green))))
 `(font-lock-variable-name-face ((t :foreground ,(+ygc 'navy))))
 `(font-lock-string-face ((t :foreground ,(+ygc 'olive))))
 `(magit-section-highlight ((t :background ,(+ygc 'alt-background) :weight normal :extend t)))
 `(show-paren-match ((t :background "#c6c6c6" :foreground ,(+ygc 'navy) :weight bold))))
