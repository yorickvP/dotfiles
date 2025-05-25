{ lib, config, options, pkgs, ... }: let
  epkgs = pkgs.emacsPackagesFor pkgs.emacs-unstable-pgtk;
in {
  programs.emacs = {
    enable = true;
    package = pkgs.emacs30-pgtk;
    extraConfig = ''
      (setq copilot-node-executable "${pkgs.nodejs-slim_20}/bin/node")
      (setq lsp-nix-server-path "${pkgs.nil}/bin/nil")
    '';
    overrides = final: prev: {
      # TODO: update
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
      aidermacs = final.melpaBuild rec {
        pname = "aidermacs";
        version = "20250221";
        commit = "e06f47cea7670d8ffff0a4b9968796a00bbeb56f";

        src = pkgs.fetchFromGitHub {
          owner = "MatthewZMD";
          repo = pname;
          rev = commit;
          hash = "sha256-cmY7OaNgp+fEwgVpuslFENv2A02OaPnDzr7kNmVLT8o=";
        };
        postPatch = "rm aidermacs-helm.el";
        packageRequires = with final; [ transient vterm ];

        recipe = pkgs.writeText "recipe" ''
          (aidermacs
          :repo "MatthewZMD/aidermacs"
          :fetcher github
          :files ("*.el"))
        '';
      };
    };
    extraPackages = p:
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
        magit-gptcommit
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
    (pkgs.runCommand "all-the-icons-fonts" {} ''
      mkdir -p $out/share/fonts/truetype
      cp ${epkgs.melpaPackages.all-the-icons.src}/fonts/*.ttf $_
    '')
  ];
  # todo: precompile?
  home.file.".emacs.d/init.el".source = ../emacs/init.el;
  home.file.".emacs.d/early-init.el".source = ../emacs/early-init.el;
}
