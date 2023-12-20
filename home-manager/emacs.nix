{ lib, config, options, pkgs, ... }: let
  epkgs = pkgs.emacsPackagesFor pkgs.emacs-unstable-pgtk;
in {
  programs.emacs = {
    enable = true;
    package = pkgs.emacs29-pgtk;
    extraConfig = ''
      (setq copilot-node-executable "${pkgs.nodejs-slim-18_x}/bin/node")
      (setq lsp-nix-server-path "${pkgs.nil}/bin/nil")
    '';
    overrides = final: prev: {
      copilot = final.melpaBuild rec {
          pname = "copilot";
          version = "20231220";
          commit = "d4fa14cea818e041b4a536c5052cf6d28c7223d7";

          src = pkgs.fetchFromGitHub {
            owner = "zerolfx";
            repo = "copilot.el";
            rev = commit;
            hash = "sha256-Tzs0Dawqa+OD0RSsf66ORbH6MdBp7BMXX7z+5UuNwq4=";
          };

          packageRequires = with final; [ dash editorconfig s ];

          recipe = pkgs.writeText "recipe" ''
            (copilot
            :repo "zerolfx/copilot.el"
            :fetcher github
            :files ("dist" "*.el"))
          '';

          meta.description = "Emacs plugin for GitHub Copilot";
        };
    };
    extraPackages = p:
      (with p; [
        treesit-grammars.with-all-grammars
        all-the-icons
        avy
        company
        company-box
        counsel
        counsel-projectile
        copilot
        diminish
        direnv
        dune
        tuareg
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
        lua-mode
        linum-relative
        lsp-haskell
        lsp-pyright
        lsp-ivy
        lsp-mode
        lsp-ui
        lsp-treemacs
        magit
        markdown-mode
        neotree
        nix-buffer
        nix-mode
        org-bullets
        org-ref
        pandoc-mode
        projectile
        reason-mode
        rescript-mode
        request
        s
        solarized-theme
        swiper
        terraform-mode
        treemacs
        use-package
        vue-mode
        weechat
        which-key
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
    (pkgs.runCommand "all-the-icons-fonts" {} ''
      mkdir -p $out/share/fonts/truetype
      cp ${epkgs.melpaPackages.all-the-icons.src}/fonts/*.ttf $_
    '')
  ];
  # todo: precompile?
  home.file.".emacs.d/init.el".source = ../emacs/init.el;
  home.file.".emacs.d/early-init.el".source = ../emacs/early-init.el;
}
