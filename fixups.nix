(pkgs: super: {
  # https://github.com/NixOS/nixpkgs/pull/278153
  nats-server = super.buildGoModule rec {
    pname = "nats-server";
    version = "2.10.11";
    src = pkgs.fetchFromGitHub {
      owner = "nats-io";
      repo = pname;
      rev = "v${version}";
      hash = "sha256-fRbjAqu1tFLUUk7aeIkEifcWkDUhNCbVZ957b2ntD+o=";
    };
    doCheck = false;
    vendorHash = "sha256-lVCWTZvzLkYl+o+EUQ0kzIhgl9C236w9i3RRA5o+IAw=";
  };
})
