(pkgs: super: {
  # ghostty is patched in flake.nix
  swaybg = super.swaybg.override {
    wrapGAppsNoGuiHook = null;
  };
})
