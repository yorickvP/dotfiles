self: super: {

  ftb = self.callPackage ../pkgs/ftb.nix {};
  pyroscope = self.callPackage ../pkgs/pyroscope {};
  nottetris2 = self.callPackage ../pkgs/nottetris2.nix {};
  #lejos = self.callPackage ../pkgs/lejos.nix {};
  libinput-gestures = super.libinput-gestures.override { extraUtilsPath = [
    self.xdotool self.python3
  ];};
  gitFire = super.stdenv.mkDerivation {
    src = super.fetchFromGitHub {
      owner = "qw3rtman";
      repo = "git-fire";
      rev = "f485fffedbc4f719c55547be22ccd0080e592c9a";
      sha256 = "1f7m1rypir85p33bgaggw5kgxjv7qy69zn1ci3b26rxr2a06fqwy";
    };
    name = "git-fire";
    installPhase = ''
      mkdir -p $out/bin/
      install git-fire $out/bin/
    '';
  };

  weiightminder = self.callPackage (builtins.fetchGit {
    url = https://gist.github.com/yorickvP/229d21a7da13c9c514dbd26147822641;
    rev = "9749ef4d83c0078bc0248215ee882d7124827cf3";
  }) {};


  yscripts = self.callPackage /home/yorick/dotfiles/bin {};
}
