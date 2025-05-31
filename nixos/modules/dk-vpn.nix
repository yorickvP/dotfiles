{
  config,
  name,
  lib,
  ...
}:
let
  cfg = config.yorick.dk-vpn;
in
{
  options.yorick.dk-vpn = with lib; {
    enable = mkEnableOption "dk vpn";
    ip = mkOption {
      type = types.str;
      example = "10.100.0.2";
    };
  };
  config = lib.mkIf cfg.enable {

    age.secrets.wg-dk.file = ../../secrets/wg.dk.${name}.age;
    networking.wireguard.interfaces.wg-dk = {
      privateKeyFile = config.age.secrets.wg-dk.path;
      ips = [ "${cfg.ip}/32" ];
      peers = [
        {
          publicKey = "teCEYc4KWT6rGchNOp6sIFO0jmkhwTjv6reOzGscAm8=";
          endpoint = "dk-1.datakami.nl:51820";
          allowedIPs = [ "10.100.0.0/24" ];
          persistentKeepalive = 25;
        }
      ];
    };
  };
}
