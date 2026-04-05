{
  lib,
  buildGoModule,
}:
buildGoModule {
  pname = "cert-agent";
  version = "unstable";
  src = lib.fileset.toSource {
    root = ./.;
    fileset = lib.fileset.unions [
      ./certs.go
      ./go.mod
      ./go.sum
    ];
  };
  vendorHash = "sha256-ZHZIKxue/gixpTNBVnIceXMTj79lrIquO7KQY+x9EHo=";
}
