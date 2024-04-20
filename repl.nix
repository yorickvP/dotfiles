let flake = builtins.getFlake ("git+file:" + toString ./.);
in {
  inherit flake;
} // flake.legacyPackages.${builtins.currentSystem} // flake.nixosConfigurations
