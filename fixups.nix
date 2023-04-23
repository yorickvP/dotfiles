(pkgs: super: {
  # https://github.com/nix-community/emacs-overlay/issues/312#issuecomment-1506416929
  emacsUnstablePgtk = super.emacsUnstablePgtk.overrideAttrs (prev: {
    postFixup = builtins.replaceStrings [ "/bin/emacs" ] [ "/bin/.emacs-*-wrapped" ] prev.postFixup;
  });
})
