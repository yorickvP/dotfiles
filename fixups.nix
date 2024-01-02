(pkgs: super: {
  # https://github.com/NixOS/nixpkgs/pull/278153
  nats-server = super.buildGoModule rec {
    pname = "nats-server";
    version = "2.10.7";
    src = pkgs.fetchFromGitHub {
      owner = "nats-io";
      repo = pname;
      rev = "v${version}";
      hash = "sha256-DZ0a4gptTjuSVBlhDEWKTmU6Dgt36xulfjVK1kJtXhI=";
    };
    doCheck = false;
    vendorHash = "sha256-Q2wc4esu2H81ct9TUPs+ysT3LrW698+9JllbvdDa5Yc=";
  };
})
