let flake = builtins.getFlake (toString ./.);
in {
  inherit flake;
} // flake.legacyPackages.${builtins.currentSystem} // flake.nixosConfigurations
