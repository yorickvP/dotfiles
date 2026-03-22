{
  lib,
  buildGoModule,
  installShellFiles,
  makeWrapper,
  nix,
  systemd,
}:

buildGoModule rec {
  pname = "y-nix-ci-puller";
  version = "0.1.0";

  src = ./.;

  vendorHash = "sha256-Db09ftEG9DJgN6mb4LaA2cOGiOjQx36DzeDqzAik2Fs=";

  nativeBuildInputs = [
    installShellFiles
    makeWrapper
  ];

  postInstall = ''
    install -Dm755 ${./y-nix-ci-apply} $out/bin/y-nix-ci-apply
    wrapProgram $out/bin/y-nix-ci-apply \
      --prefix PATH : ${
        lib.makeBinPath [
          nix
          systemd
        ]
      }
  '';

  meta = with lib; {
    description = "Pull CI-built nix store paths via MQTT and create GC roots";
    maintainers = [ ];
    platforms = platforms.linux;
  };
}
