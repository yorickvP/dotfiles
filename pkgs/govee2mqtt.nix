{ lib, fetchFromGitHub, rustPlatform, govee2mqtt, pkg-config, openssl }:

rustPlatform.buildRustPackage rec {
  pname = "govee2mqtt";
  version = "2024.06.15-patched";
  src = fetchFromGitHub {
    owner = "yorickvP";
    repo = pname;
    rev = "968b98a2efb7174ac34989b6383e5d21249e567f";
    hash = "sha256-U8cxmQoWlNtBvVwCSPAkPP2rJbWM2DVnN/CvPMU2wpQ=";
  };
  cargoHash = "sha256-/iAK6Vp6tCW5W1fsA2S9TqGml2EvyBMMwovMt/oVDSo=";
  cargoPatches = [ ./dont-vendor-openssl.patch ];

  nativeBuildInputs = [ pkg-config ];
  buildInputs = [ openssl ];

  postPatch = ''
    substituteInPlace src/service/http.rs \
      --replace '"assets"' '"${placeholder "out"}/share/govee2mqtt/assets"'
  '';

  postInstall = ''
    mkdir -p $out/share/govee2mqtt/
    cp -r assets $out/share/govee2mqtt/
  '';
  inherit (govee2mqtt) meta;
}
