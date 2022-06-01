{ lib, config, options, pkgs, ... }: let
  epkgs = pkgs.emacsPackagesFor pkgs.emacsPgtkNativeComp;
  engpkgs = pkgs.emacsPackagesNgFor pkgs.emacsPgtkNativeComp;
in {
  programs.emacs = {
    enable = true;
    package = pkgs.emacsPgtkNativeComp;
    extraPackages = _:
      (with epkgs.melpaPackages; [
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
        flycheck-inline
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
        evil-mc
        notmuch
        org-cliplink
        ox-mediawiki
        rust-mode
        undo-tree
      ]);
  };
  

  fonts.fontconfig.enable = true;
  home.packages = [
    pkgs.rnix-lsp
    (pkgs.runCommand "all-the-icons-fonts" {} ''
      mkdir -p $out/share/fonts/truetype
      cp ${epkgs.melpaPackages.all-the-icons.src}/fonts/*.ttf $_
    '')
  ];
  # todo: precompile?
  home.file.".emacs.d/init.el".source = ../emacs/init.el;
  home.file.".emacs.d/early-init.el".source = ../emacs/early-init.el;
}
