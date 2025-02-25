(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(custom-safe-themes
   '("efcecf09905ff85a7c80025551c657299a4d18c5fcfedd3b2f2b6287e4edd659" "51ec7bfa54adf5fff5d466248ea6431097f5a18224788d0bd7eb1257a4f7b773" "5a00018936fa1df1cd9d54bee02c8a64eafac941453ab48394e2ec2c498b834a" "2ce76d65a813fae8cfee5c207f46f2a256bac69dacbb096051a7a8651aa252b0" "4594d6b9753691142f02e67b8eb0fda7d12f6cc9f1299a49b819312d6addad1d" "7e377879cbd60c66b88e51fad480b3ab18d60847f31c435f15f5df18bdb18184" "74e2ed63173b47d6dc9a82a9a8a6a9048d89760df18bc7033c5f91ff4d083e37" "3c7a784b90f7abebb213869a21e84da462c26a1fda7e5bd0ffebf6ba12dbd041" "0170347031e5dfa93813765bc4ef9269a5e357c0be01febfa3ae5e5fcb351f09" "249e100de137f516d56bcf2e98c1e3f9e1e8a6dce50726c974fa6838fbfcec6b" "9cd57dd6d61cdf4f6aef3102c4cc2cfc04f5884d4f40b2c90a866c9b6267f2b3" "b95f61aa5f8a54d494a219fcde9049e23e3396459a224631e1719effcb981dbd" "06ed754b259cb54c30c658502f843937ff19f8b53597ac28577ec33bb084fa52" "788121c96b7a9b99a6f35e53b7c154991f4880bb0046a80330bb904c1a85e275" "014cb63097fc7dbda3edf53eb09802237961cbb4c9e9abd705f23b86511b0a69" "4825b816a58680d1da5665f8776234d4aefce7908594bea75ec9d7e3dc429753" "285d1bf306091644fb49993341e0ad8bafe57130d9981b680c1dbd974475c5c7" "524fa911b70d6b94d71585c9f0c5966fe85fb3a9ddd635362bfabd1a7981a307" "76ddb2e196c6ba8f380c23d169cf2c8f561fd2013ad54b987c516d3cabc00216" "04aa1c3ccaee1cc2b93b246c6fbcd597f7e6832a97aaeac7e5891e6863236f9f" "b11edd2e0f97a0a7d5e66a9b82091b44431401ac394478beb44389cf54e6db28" "6fc9e40b4375d9d8d0d9521505849ab4d04220ed470db0b78b700230da0a86c1" "6bdc4e5f585bb4a500ea38f563ecf126570b9ab3be0598bdf607034bb07a8875" "4c56af497ddf0e30f65a7232a8ee21b3d62a8c332c6b268c81e9ea99b11da0d3" "fee7287586b17efbfda432f05539b58e86e059e78006ce9237b8732fde991b4c" "8db4b03b9ae654d4a57804286eb3e332725c84d7cdab38463cb6b97d5762ad26" "d677ef584c6dfc0697901a44b885cc18e206f05114c8a3b7fde674fce6180879" "a8245b7cc985a0610d71f9852e9f2767ad1b852c2bdea6f4aadc12cce9c4d6d0" "8aebf25556399b58091e533e455dd50a6a9cba958cc4ebb0aab175863c25b9a4" default))
 '(lsp-bridge-python-multi-lsp-server "pyright_ruff")
 '(notmuch-saved-searches
   '((:name "unread" :query "tag:unread" :key "u")
     (:name "flagged" :query "tag:flagged" :key "f")
     (:name "sent" :query "tag:sent" :key "t")
     (:name "drafts" :query "tag:draft" :key "d")
     (:name "all mail" :query "*" :key "a")
     (:name "inbox" :query "tag:inbox")))
 '(safe-local-variable-values
   '((transient-values
      (magit-commit "--signoff"))
     (magit-status-mode
      (transient-values
       (magit-commit "--signoff")))
     (magit-commit-signoff quote t)
     (magit-commit-signoff 't)
     (flycheck-gcc-language-standard . "c++11")
     (flycheck-clang-language-standard . "c++11")
     (c-block-comment-prefix . "  ")
     (eval c-set-offset 'inlambda 0)
     (eval c-set-offset 'arglist-cont-nonempty
           '(c-lineup-gcc-asm-reg c-lineup-arglist))
     (eval c-set-offset 'arglist-close 0)
     (eval c-set-offset 'arglist-intro '++)
     (eval c-set-offset 'case-label 0)
     (eval c-set-offset 'statement-case-open 0)
     (eval c-set-offset 'access-label '-)
     (eval c-set-offset 'substatement-open 0)
     (eval c-set-offset 'arglist-cont-nonempty '+)
     (eval c-set-offset 'arglist-cont 0)
     (eval c-set-offset 'arglist-intro '+)
     (eval c-set-offset 'inline-open 0)
     (eval c-set-offset 'defun-open 0)
     (eval c-set-offset 'innamespace 0)
     (indicate-empty-lines . t)))
 '(warning-suppress-types '((comp))))
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
