{ lib, config, options, pkgs, ... }: {
  programs.emacs = {
    enable = true;
    package = pkgs.emacsPgtkGcc;
    extraPackages = _:
      let epkgs = pkgs.emacsPackagesFor pkgs.emacsPgtkGcc;
      in (with epkgs.melpaPackages; [
        reason-mode
        evil
        counsel
        ivy
        ivy-hydra
        swiper
        magit
        forge
        avy
        lsp-mode
        (lsp-ui.overrideAttrs (o: {
          src = pkgs.fetchFromGitHub {
            owner = "emacs-lsp";
            repo = "lsp-ui";
            rev = "240a7de26400cf8b13312c3f9acf7ce653bdaa8a";
            sha256 = "1zscdjlnkx43i4kw2qmlvji23xfpw7n5y4v99ld33205dg905fsy";
          };
        }))
        lsp-haskell
        flycheck
        lsp-ivy
      ]) ++ (with epkgs.melpaPackages; [
        epkgs.undo-tree
        epkgs.notmuch
        epkgs.rust-mode
        pkgs.emacsPackagesNg.crdt
        company
        projectile
        counsel-projectile
        ggtags
        use-package
        org-bullets
        solarized-theme
        evil-leader
        evil-surround # evil-magit
        epkgs.evil-goggles
        epkgs.ox-mediawiki
        nix-buffer
        which-key
        git-gutter-fringe
        all-the-icons
        epkgs.org-cliplink
        pandoc-mode
        markdown-mode
        #interleave
        org-ref
        haskell-mode
        request # intero
        weechat
        s
        elixir-mode
        htmlize
        linum-relative
        terraform-mode
        direnv
        vue-mode
        solarized-theme
        nix-mode
      ]);
  };

  # todo: precompile?
  home.file.".emacs.d/init.el".source = ../emacs/init.el;
  home.file.".emacs.d/early-init.el".source = ../emacs/early-init.el;
}
