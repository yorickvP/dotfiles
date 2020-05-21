{ lib, config, pkgs, ... }:

{
  imports =
    [ <yori-nix/physical/hp8570w.nix>
      <yori-nix/roles/workstation.nix>
    ];

  system.stateVersion = "17.09";

  nix = {
    binaryCaches = [
      "https://cache.nixos.org"
      "https://disciplina.cachix.org"
    ];
    trustedUsers = [ "root" "lars" ];
  };
  users.users.lars = {
    isNormalUser = true;
    openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDBze0fBV/Fpz9bz1WKkbPlj8h526ZfduOcQVlA+7j0+yzlT+jX6nLNjXNmIi6JZoERj8lG4/avkagldj+wwqWrKM2xOMgIUx34i+br5+U4Y7DedljfPV9k8eE55SI4BjfO697V7BhHP4eooRUjNVmqSmRAld06hJzMj7irGWHK+RPrK0M1BvGgSV5pL50jzQGd2unxvNuxSk1rWBNfNEGt6ok0G8/ud0Gw5QbcYWzbbnKBB8JsgBct22txtcgVbRyqftD+vpFl0Oyq4tiQbSHqa8qpFyV/wTf4Cs1Zz7WrqH+2xfx+oUsCOfMKuvCI8FKtriAWEmfOM42bBi50v2kj"
    ];
  };
  boot.kernelPackages = pkgs.linuxPackages_4_19;
}
