{ stdenv
, fetchFromGitLab
, cmake
, fetchpatch
, pkg-config
, extra-cmake-modules
, qt5
, libsForQt5
}: stdenv.mkDerivation rec {
  pname = "xwaylandvideobridge";
  version = "unstable-2023-06-04";

  src = fetchFromGitLab {
    domain = "invent.kde.org";
    owner = "system";
    repo = "xwaylandvideobridge";
    rev = "75f68526fb3d2a4e1af6644e49dfdc8d9e56985c";
    hash = "sha256-GvutiwF9FxtZ2ehd6dsR3ZY8Mq6/4k1TDpz+xE8SusE=";
  };

  nativeBuildInputs = [
    cmake
    extra-cmake-modules
    pkg-config
    qt5.wrapQtAppsHook
  ];

  patches = [
    (fetchpatch {
      url = "https://aur.archlinux.org/cgit/aur.git/plain/cursor-mode.patch?h=xwaylandvideobridge-cursor-mode-2-git";
      hash = "sha256-649kCs3Fsz8VCgGpZ952Zgl8txAcTgakLoMusaJQYa4=";
    })
  ];

  buildInputs = [
    qt5.qtbase
    qt5.qtquickcontrols2
    qt5.qtx11extras
    libsForQt5.kdelibs4support
    (libsForQt5.kpipewire.overrideAttrs (oldAttrs: {
      version = "5.27.5";

      src = fetchFromGitLab {
        domain = "invent.kde.org";
        owner = "plasma";
        repo = "kpipewire";
        rev = "v5.27.5";
        hash = "sha256-xcuSWURiyY9iuayeY9w6G59UJTbYXyPWGg8x+EiXNsY=";
      };
    }))
  ];
}
