;; installed by home-manager
;; temporarily disable GC
(setq gc-cons-threshold most-positive-fixnum ; 2^61 bytes
      gc-cons-percentage 0.6)

;; re-enable GC later
(add-hook 'emacs-startup-hook
  (lambda ()
    (setq gc-cons-threshold 100000000
          gc-cons-percentage 0.1)))

;; disable toolbars before GUI shows
(tool-bar-mode 0)
(menu-bar-mode 0)
(scroll-bar-mode 0)

;; we use a tiling WM, so don't attempt any window resizes
(setq frame-inhibit-implied-resize t)

;; magic package quickstart feature
(setq package-quickstart 't)

(set-face-attribute 'default nil
                    :family "monospace"
                    :height 120
                    :weight 'normal
                    :width 'normal)

;; don't redisplay during startup
(setq-default inhibit-redisplay t
              inhibit-message t)
(add-hook 'window-setup-hook
          (lambda ()
            (setq-default inhibit-redisplay nil
                          inhibit-message nil)
            (redisplay)))
