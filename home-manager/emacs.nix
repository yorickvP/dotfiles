{
  lib,
  config,
  options,
  pkgs,
  ...
}:
let
  epkgs = pkgs.emacsPackagesFor pkgs.emacs-unstable-pgtk;
in
{
  programs.emacs = {
    enable = true;
    package = pkgs.emacs30-pgtk;
    extraConfig = ''
      (setq lsp-nix-server-path "${pkgs.nil}/bin/nil")
    '';
    overrides = final: prev: {
      copilot = final.melpaBuild rec {
        pname = "copilot";
        version = "20250506";
        commit = "fe3f51b636dea1c9ac55a0d5dc5d7df02dcbaa48";

        src = pkgs.fetchFromGitHub {
          owner = "copilot-emacs";
          repo = "copilot.el";
          rev = commit;
          hash = "sha256-reoIFMjx2Go/EPAxD+OQFxge/amqguZS+jteh0b9xgA";
        };

        packageRequires = with final; [
          editorconfig
          f
        ];

        recipe = pkgs.writeText "recipe" ''
          (copilot
          :repo "copilot-emacs/copilot.el"
          :fetcher github
          :files ("dist" "*.el"))
        '';

        meta.description = "Emacs plugin for GitHub Copilot";
      };
    };
    extraPackages =
      p:
      (with p; [
        # evil-magit
        all-the-icons
        avy
        company
        company-box
        consult
        copilot
        crdt
        direnv
        doom-modeline
        dune
        elixir-mode
        evil
        evil-goggles
        evil-leader
        evil-mc
        evil-surround
        flycheck
        flycheck-inline
        flymake-flycheck
        forge
        ggtags
        haskell-mode
        htmlize
        linum-relative
        lsp-haskell
        lsp-mode
        lsp-pyright
        lsp-treemacs
        lsp-ui
        lua-mode
        magit
        markdown-mode
        nix-buffer
        nix-mode
        notmuch
        orderless
        org-bullets
        org-cliplink
        org-ref
        ox-mediawiki
        pandoc-mode
        request
        rescript-mode
        rust-mode
        s
        solarized-theme
        terraform-mode
        treemacs
        treesit-grammars.with-all-grammars
        tuareg
        undo-tree
        use-package
        vertico
        vue-mode
        vundo
        which-key
        marginalia
        kind-icon
        corfu
        corfu-terminal
        cape
        embark
        embark-consult
        hide-mode-line
        llm
        gptel
        # magit-gptcommit
        # consult-web
        diff-hl
        highlight-indent-guides
        vterm
        treemacs-evil
        treemacs-magit
        treemacs-nerd-icons
        nerd-icons-dired
        nerd-icons-completion
        color-theme-sanityinc-tomorrow
        catppuccin-theme
        solaire-mode
        doom-themes
        nano-theme
        kaolin-themes
        hledger-mode
        lsp-bridge
        aidermacs
      ]);
  };

  fonts.fontconfig.enable = true;
  home.packages = [
    (pkgs.runCommand "all-the-icons-fonts" { } ''
      mkdir -p $out/share/fonts/truetype
      cp ${epkgs.melpaPackages.all-the-icons.src}/fonts/*.ttf $_
    '')
  ];
  # todo: precompile?
  home.file.".emacs.d/init.el".source = ../emacs/init.el;
  home.file.".emacs.d/early-init.el".source = ../emacs/early-init.el;
}
