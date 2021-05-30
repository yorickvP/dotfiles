let sources = import ./nix/sources.nix;
in {
  allowUnfree = true;
  # chromium.vaapiSupport = true;
  android_sdk.accept_license = true;
  overlays = import ./overlays.nix;
}
