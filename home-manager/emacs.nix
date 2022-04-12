{ lib, config, options, pkgs, ... }: {
  programs.emacs = {
    enable = true;
    package = pkgs.emacsPgtkGcc;
    extraPackages = _:
      let epkgs = pkgs.emacsPackagesFor pkgs.emacsPgtkGcc;
          engpkgs = pkgs.emacsPackagesNgFor pkgs.emacsPgtkGcc;
          lsp-ui = epkgs.melpaPackages.lsp-ui.overrideAttrs (o: {
            src = pkgs.fetchFromGitHub {
              owner = "emacs-lsp";
              repo = "lsp-ui";
              rev = "240a7de26400cf8b13312c3f9acf7ce653bdaa8a";
              sha256 = "1zscdjlnkx43i4kw2qmlvji23xfpw7n5y4v99ld33205dg905fsy";
            };
          });
      in (with epkgs.melpaPackages; [
        all-the-icons
        avy
        company
        counsel
        counsel-projectile
        diminish
        direnv
        elixir-mode
        evil
        evil-leader
        # evil-magit
        evil-surround
        flycheck
        forge
        ggtags
        git-gutter-fringe
        haskell-mode
        htmlize
        ivy
        ivy-hydra
        linum-relative
        lsp-haskell
        lsp-ivy
        lsp-mode
        lsp-ui
        magit
        markdown-mode
        nix-buffer
        nix-mode
        org-bullets
        org-ref
        pandoc-mode
        projectile
        reason-mode
        request
        s
        solarized-theme
        swiper
        terraform-mode
        use-package
        vue-mode
        weechat
        which-key
      ]) ++ (with engpkgs; [
        crdt
        doom-modeline
        evil-goggles
        notmuch
        org-cliplink
        ox-mediawiki
        rust-mode
        undo-tree
      ]);
  };

  # todo: precompile?
  home.file.".emacs.d/init.el".source = ../emacs/init.el;
  home.file.".emacs.d/early-init.el".source = ../emacs/early-init.el;
}
