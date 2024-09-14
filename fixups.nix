(pkgs: super: {
  tailscale = super.buildGoModule (rec {
    inherit (super.tailscale) pname patches nativeBuildInputs CGO_ENABLED subPackages
      tags doCheck postInstall meta;
    version = "1.72.1";
    ldflags = [
      "-w"
      "-s"
      "-X tailscale.com/version.longStamp=${version}"
      "-X tailscale.com/version.shortStamp=${version}"
    ];
    src = super.fetchFromGitHub {
      owner = "tailscale";
      repo = "tailscale";
      rev = "v${version}";
      hash = "sha256-b1o3UHotVs5/+cpMx9q8bvt6BSM2QamLDUNyBNfb58A=";
    };
    vendorHash = "sha256-M5e5dE1gGW3ly94r3SxCsBmVwbBmhVtaVDW691vxG/8=";
  });
})
