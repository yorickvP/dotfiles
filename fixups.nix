(pkgs: super: {
  # https://github.com/nix-community/emacs-overlay/issues/329#issuecomment-1571155533
  emacsUnstablePgtk = super.emacsUnstablePgtk.overrideAttrs (prev: {
    withTreeSitter = true;
  });
})
