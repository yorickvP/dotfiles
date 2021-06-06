(self: super: {

  yori-cc = super.callPackage ./yori-cc.nix { };

  ftb = super.callPackage ./ftb.nix {};
  pyroscope = super.callPackage ./pyroscope {};
  #lejos = super.callPackage ../pkgs/lejos.nix {};

  weiightminder = super.callPackage (builtins.fetchGit {
    url = https://gist.github.com/yorickvP/229d21a7da13c9c514dbd26147822641;
    rev = "9749ef4d83c0078bc0248215ee882d7124827cf3";
  }) {};


  yscripts = super.callPackage ../bin {};
  factorio = super.factorio.override {
    releaseType = "alpha";
    username = "yorickvp";
    token = (import ../nixos/secrets.nix).factorio_token;
  };

})
