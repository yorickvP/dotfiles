{ lib, config, options, pkgs, ... }:
let user = "yorick.van.pelt";
in {
  programs.ssh = {
    matchBlocks = let
      lumigod = hostname: {
        inherit hostname user;
        port = 2233;
      };
      lumivpn = {
        inherit user;
        # verified by wireguard key
        extraOptions.StrictHostKeyChecking = "no";
      };
    in rec {
      athena = {
        hostname = "athena.lumi.guide";
        inherit user;
      };
      rpibuild3 = {
        hostname = "10.110.0.3";
        inherit user;
        port = 4222;
      };
      rpibuild4 = {
        hostname = "rpibuild4.lumi.guide";
        inherit user;
        port = 4222;
      };
      styx = lumigod "10.110.0.1";
      "*.lumi.guide" = { inherit user; };
      zeus = lumigod "zeus.lumi.guide";
      ponos = lumigod "ponos.lumi.guide";
      medusa = lumigod "lumi.guide";
      # signs
      "10.108.0.*" = lumivpn // { port = 4222; };
      "10.109.0.*" = lumivpn;
      "10.110.0.*" = lumivpn // { port = 2233; };
      "10.111.0.*" = lumivpn;
      "192.168.42.*" = { inherit user; };
    };
    extraConfig = ''
      Match host "192.168.42.*" exec "ip route get %h | grep -q via"
        ProxyJump athena
    '';
  };
  programs.fish.shellAliases.lumi =
    "pushd ~/engineering/lumi; cached-nix-shell; popd";
}
