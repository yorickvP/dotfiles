(pkgs: super: {
  dhcpcd = super.dhcpcd.overrideAttrs (o: rec {
    version = "10.0.8";
    src = pkgs.fetchFromGitHub {
      owner = "NetworkConfiguration";
      repo = "dhcpcd";
      rev = "v${version}";
      sha256 = "sha256-kM+mdB7ul9NYHOEAJtp3M57M2MellrCoY/SaPWFLEpQ=";
    };
  });
  openssh = super.openssh.overrideAttrs (o: rec {
    version = "9.8p1";
    src = pkgs.fetchurl {
      url = "mirror://openbsd/OpenSSH/portable/openssh-${version}.tar.gz";
      hash = "sha256-3YvQAqN5tdSZ37BQ3R+pr4Ap6ARh9LtsUjxJlz9aOfM=";
    };
  });
})
