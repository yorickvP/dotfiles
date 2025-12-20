{ buildGoModule }:
buildGoModule {
  name = "wg-restarter";
  src = ./.;
  vendorHash = null;
}
