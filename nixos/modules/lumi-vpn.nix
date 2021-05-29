{ config, lib, ... }:
let
  cfg = config.yorick.lumi-vpn;
  addresses = import
    "${builtins.getEnv "HOME"}/engineering/lumi/os/gateway/addresses.nix" {
      lib.ip4.ip = a: b: c: d: x:
        lib.concatStringsSep "." (map toString [ a b c d ]);
    };
in {
  options.yorick.lumi-vpn = with lib; {
    enable = mkEnableOption "lumi vpn";
    name = mkOption {
      type = types.str;
      example = "yorick-homepc";
    };
    user = mkOption {
      type = types.str;
      default = "yorick";
    };
    mtu = mkOption {
      type = types.int;
      default = 1371; # 1408 at home
    };
    ip = mkOption {
      type = types.str;
      example = "10.109.0.1";
      default = addresses.workstations."${cfg.name}";
    };
  };
  config = lib.mkIf cfg.enable {
    networking.wireguard.interfaces = {
      wg-lumi = {
        privateKeyFile =
          "/home/${cfg.user}/engineering/lumi/secrets/devel/vpn/wg/workstations.${cfg.name}.key";
        ips = [ cfg.ip ];
        peers = [{
          publicKey = "6demp+PX2XyVoMovDj4xHQ2ZHKoj4QAF8maWpjcyzzI=";
          endpoint = "wg.lumi.guide:31727";
          allowedIPs = [ "10.96.0.0/12" "10.0.0.0/17" ];
        }];
        postSetup = "ip link set dev wg-lumi mtu ${toString cfg.mtu}";
      };
    };
  };
}
