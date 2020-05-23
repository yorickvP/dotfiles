{lib, config, ...}:
let
  cfg = config.services.yorick.torrent-vpn;
in
{
  options.services.yorick.torrent-vpn = with lib; {
    enable = mkEnableOption "torrent-vpn";
    name = mkOption { type = types.str; };
    namespace = mkOption { type = types.str; };
  };
  config = {
    deployment.keyys = [ (<yori-nix/keys>+"/wg.${cfg.name}.key") ];
    networking.wireguard.interfaces.${cfg.name} = {
      # curl -s https://api.mullvad.net/www/relays/all/ | jq '.[] | select(.type == "wireguard" and .country_code == "nl")'
      ips = ["10.64.19.76/32" "fc00:bbbb:bbbb:bb01::1:134b/128"];
      privateKeyFile = "/root/keys/wg.${cfg.name}.key";
      peers = [{
        publicKey = "hnRyse6QxPPcZOoSwRsHUtK1W+APWXnIoaDTmH6JsHQ=";
        allowedIPs = ["0.0.0.0/0" "::0/0"];
        endpoint = "185.65.134.224:31173";
      }];
      interfaceNamespace = cfg.namespace;
    };
    systemd.services."wireguard-${cfg.name}" = {
      preStart = ''
        ip netns add "${cfg.namespace}"
      '';
      postStop = ''
        ip netns del "${cfg.namespace}"
      '';
    };
    environment.etc."netns/torrent/resolv.conf".text = ''
      nameserver 193.138.218.74
    '';
  };
}
# todo: presets
