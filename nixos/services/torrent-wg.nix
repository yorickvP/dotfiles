{ pkgs, lib, config, ... }:
let cfg = config.services.yorick.torrent-vpn;
in {
  options.services.yorick.torrent-vpn = with lib; {
    enable = mkEnableOption "torrent-vpn";
    name = mkOption { type = types.str; };
    namespace = mkOption { type = types.str; };
  };
  config = {
    age.secrets.wg-torrent.file = ../../secrets/wg.${cfg.name}.age;
    networking.wireguard.interfaces.${cfg.name} = {
      # curl -s https://api.mullvad.net/www/relays/all/ | jq '.[] | select(.type == "wireguard" and .country_code == "nl")'
      ips = [ "10.66.30.26/32" "fc00:bbbb:bbbb:bb01::3:1e19/128" ];
      privateKeyFile = config.age.secrets.wg-torrent.path;
      peers = [{
        publicKey = "hnRyse6QxPPcZOoSwRsHUtK1W+APWXnIoaDTmH6JsHQ=";
        allowedIPs = [ "0.0.0.0/0" "::0/0" ];
        endpoint = "[2a03:1b20:3:f011::a04f]:51820";
      }];
      interfaceNamespace = cfg.namespace;
      preSetup = ''
        ${pkgs.iproute}/bin/ip netns add "${cfg.namespace}" || true
      '';
    };
    environment.etc."netns/torrent/resolv.conf".text = ''
      nameserver 193.138.218.74
    '';
  };
}
# todo: presets
