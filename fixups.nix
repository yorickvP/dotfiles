(pkgs: super: {
  # https://github.com/nix-community/emacs-overlay/issues/329#issuecomment-1571155533
  emacs-unstable-pgtk = super.emacs-unstable-pgtk.overrideAttrs (prev: {
    withTreeSitter = true;
  });
})
