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
})
