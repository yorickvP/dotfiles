(pkgs: super: {
  # ghostty is patched in flake.nix
  swaybg = super.swaybg.override {
    wrapGAppsNoGuiHook = null;
  };
  bitwarden-desktop = super.bitwarden-desktop.overrideAttrs (o: {
    preBuild = ''
      ${o.preBuild}
      pushd apps/desktop/desktop_native/proxy
      cargo build --bin desktop_proxy --release
      popd
    '';
    postInstall = ''
      ${o.postInstall or ""}
      mkdir -p $out/bin
      cp -r apps/desktop/desktop_native/target/release/desktop_proxy $out/bin
    '';
  });
})
