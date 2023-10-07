{ stdenv, libevdev, xdotool, xorg, pkg-config, fetchFromGitHub }:
stdenv.mkDerivation {
  pname = "wayland-push-to-talk-fix";
  version = "0.1";
  src = fetchFromGitHub {
    owner = "Rush";
    repo = "wayland-push-to-talk-fix";
    rev = "76c3227ede4b9e5881521826f47e396556eb7a63";
    hash = "sha256-Wkt0MrCJH2IYvlewGUin49flM7bFlHpcqOkK7uks6Ho=";
  };
  nativeBuildInputs = [ pkg-config ];
  buildInputs = [ xorg.libX11 xorg.xorgproto xdotool libevdev ];
  installPhase = ''
    mkdir -p $out/bin
    cp push-to-talk $out/bin/wayland-push-to-talk-fix
  '';
}
