{
  pkgs,
  inputs,
  ...
}:
let
  sshkeys = import ../../sshkeys.nix;
in
{
  imports = [
    ../../roles/workstation.nix
  ];

  yorick.dk-vpn = {
    enable = true;
    ip = "10.100.0.7";
  };

  networking.hostId = "d05ee74c";

  system.stateVersion = "25.05";

  services.znapzend = {
    enable = true;
    zetup = {
      "rpool/home" = {
        plan = "1d=>1h,1m=>1w";
      };
      "rpool/nixos/var" = {
        plan = "1d=>1h,1m=>1w";
      };
    };
  };

  users.users = {
    judith = {
      isNormalUser = true;
      openssh.authorizedKeys.keys = sshkeys.judith;
      packages = with pkgs; [
        uv
        git
        cmake
        gnumake
        gcc
        screen
        vim
      ];
      extraGroups = [ "video" ];
    };
  };
  # From the flake's own packages (built against upstream's xrt nixpkgs fork),
  # not pkgs.fastflowlm — the overlay on our nixpkgs has no xrt.
  environment.systemPackages = [ inputs.nix-amd-npu.packages.${pkgs.system}.fastflowlm ];
}
