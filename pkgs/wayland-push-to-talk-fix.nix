{ stdenv, libevdev, xdotool, xorg, pkg-config, fetchFromGitHub }:
stdenv.mkDerivation {
  pname = "wayland-push-to-talk-fix";
  version = "0.1";
  src = fetchFromGitHub {
    owner = "yorickvP";
    repo = "wayland-push-to-talk-fix";
    rev = "57131c6983b083bb4677df9a073e66b84825b256";
    hash = "sha256-46wk4sJTqNIU01wWnlcPU5rmzZHRcgUzVnYYJy95L7A=";
  };
  nativeBuildInputs = [ pkg-config ];
  buildInputs = [ xorg.libX11 xorg.xorgproto xdotool libevdev ];
  installPhase = ''
    mkdir -p $out/bin
    cp push-to-talk $out/bin/wayland-push-to-talk-fix
  '';
}
