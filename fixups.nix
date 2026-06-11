(pkgs: super: {
  # todo: upstream
  atool = super.atool.overrideAttrs {
    configureScript = "${pkgs.buildPackages.bash}/bin/bash configure";
  };
  # ncdu 2.x needs zig, which doesn't cross-compile cleanly. Fall back to v1.
  ncdu =
    if pkgs.stdenv.buildPlatform.canExecute pkgs.stdenv.hostPlatform then super.ncdu else super.ncdu_1;
  # TODO: development/perl-modules/generic/default.nix:62
  # use perl instead of perl.mini?
  perlPackages = super.perlPackages.overrideScope (
    _pself: psuper: {
      # cross fix: Makefile.PL transitively `use B`, which the build-host
      # perl.mini can't load (no dynamic loading). Use full build perl.
      TextCSV = psuper.TextCSV.overrideAttrs (o: {
        preConfigure = ''
          export PATH=${pkgs.buildPackages.perl}/bin:$PATH
        ''
        + (o.preConfigure or "");
      });
    }
  );
  age-plugin-fido2-hmac = super.age-plugin-fido2-hmac.overrideAttrs {
    src = super.fetchFromGitHub {
      owner = "yorickvP";
      repo = "age-plugin-fido2-hmac";
      rev = "73af5848e2ad46edbeb7d861efb5da9d3390722b";
      hash = "sha256-8VGJdgm1fQ06TmrORH2iSOixK5W7LSrl76VGAjbr5Bw=";
    };
    vendorHash = "sha256-3r/eTaa4kYRXqq7sUZzzGkgcF8lZbPZguoHb6W6t1T0=";
  };
  age-plugin-sss = super.age-plugin-sss.overrideAttrs {
    src = super.fetchFromGitHub {
      owner = "yorickvP";
      repo = "age-plugin-sss";
      rev = "6aa3f406e77eaddefe27b68b0d387bb0df31ea76";
      hash = "sha256-t+A79y3PL7e0Kg6aJKDu8vpaCypEJR3gAaxNi7KOLho=";
    };
    vendorHash = "sha256-Aw7dwro6adluhQXPlZ9RZVGBAmNw539Z3c+a8TmPTXU=";
  };
})
