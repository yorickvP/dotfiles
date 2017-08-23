self: super: {

  ftb = super.callPackage ../pkgs/ftb.nix {};
  pyroscope = super.callPackage ../pkgs/pyroscope {};
  peageprint = super.callPackage ../pkgs/peageprint.nix {};
  nottetris2 = super.callPackage ../pkgs/nottetris2.nix {};
  mailpile = super.callPackage ../pkgs/mailpile.nix {};
  libinput-gestures = super.callPackage ../pkgs/libinput-gestures.nix {};
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

  weiightminder = super.callPackage (super.fetchgit {
    url = https://gist.github.com/yorickvP/229d21a7da13c9c514dbd26147822641;
    rev = "9749ef4d83c0078bc0248215ee882d7124827cf3";
    sha256 = "0kxi20ss2k22sv3ndplnklc6r7ja0lcgklw6mz43qcj7vmgxxllf";
  }) {};

  node2nix_git = (super.callPackage (super.fetchFromGitHub {
    owner = "svanderburg";
    repo = "node2nix";
    rev = "b6545937592e7e54a14a2df315598570480fee9f";
    sha256 = "1y50gs5mk2sdzqx68lr3qb71lh7jp4c38ynybf8ikx7kfkzxvasb";
  }) {}).package;

    yscripts = super.callPackage /home/yorick/dotfiles/bin {};
}
