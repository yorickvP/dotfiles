self: super: {

  myEmacs = super.emacsWithPackages (epkgs: (with epkgs.melpaStablePackages; [
    company
    paredit
    counsel
    flycheck
    ivy
    ivy-hydra
    magit
    projectile
    epkgs.melpaPackages.counsel-projectile
    ggtags
    use-package
    org-bullets
    solarized-theme
    evil
    evil-magit
    evil-leader
    evil-tutor
    evil-surround
    epkgs.evil-goggles
    epkgs.ox-mediawiki
    epkgs.hledger-mode
    # evil-commentary
    password-store
    pass
    linum-relative
    (epkgs.trivialBuild {
      pname = "emacs-nix-mode";
      src = super.fetchFromGitHub {
        owner = "matthewbauer";
        repo = "nix-mode";
        rev = "f24abeb736a028deb283d51a859e7e34aba5e42b";
        sha256 = "06kznwa5qbl3vzvvdh6lqdgzjzkvkvayvv3bjx3p2j275fxy1kfw";
      };
      preConfigure = "rm nix-company.el nix-mode-mmm.el";
    })
    nix-buffer
    which-key
    git-gutter-fringe
    neotree
    all-the-icons
    epkgs.org-cliplink
    pandoc-mode
    markdown-mode
    interleave
    # all-the-icons-dired
    org-ref
    avy
    # nixos-sandbox # https://github.com/travisbhartwell/nix-emacs
    haskell-mode
    intero
  ]));
  # todo: emacs-all-the-icons-fonts
  pandocdeps = (super.texlive.combine {
    inherit (super.texlive)
      scheme-basic
      # explicit list pandoc tex dependencies
      amsfonts amsmath lm ec ifxetex ifluatex eurosym listings fancyvrb
      # longtable
      booktabs
      hyperref ulem geometry setspace
      # linestretch
      babel
      # some optional dependencies of pandoc
      upquote microtype csquotes
      mathtools
      ;
  });
}
