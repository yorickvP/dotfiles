{ pkgs, lib, config, ... }:
let cfg = config.services.yorick.torrent-vpn;
    # curl -s 'https://api.mullvad.net/www/relays/all/' | jq '.[] | select(.type == "wireguard" and .country_code == "nl" and .owned and .active) | {hostname, pubkey, ipv4_addr_in, ipv6_addr_in}'
    mullvad_entry = builtins.fromJSON ''
        {
          "hostname": "nl-ams-wg-006",
          "pubkey": "xpZ3ZDEukbqKQvdHwaqKMUhsYhcYD3uLPUh1ACsVr1s=",
          "ipv4_addr_in": "185.65.134.86",
          "ipv6_addr_in": "2a03:1b20:3:f011::a06f",
          "status_messages": [
            {
              "message": "OpenVPN servers hosted by 31173 will be upgraded to a newer OS and some will upgrade to 20Gbps from 10Gbps. the upgrades will begin from 2023-MAR-23,  we will rotate IP-addresses and also change their hostnames to use the new naming scheme,  This will also affect WG Servers in AMS.",
              "timestamp": "2023-03-23T16:25:13+00:00"
            }
          ]
        }
    '';
in {
  options.services.yorick.torrent-vpn = with lib; {
    enable = mkEnableOption "torrent-vpn";
    name = mkOption { type = types.str; };
    namespace = mkOption { type = types.str; };
  };
  config = lib.mkIf cfg.enable {
    age.secrets.wg-torrent.file = ../../secrets/wg.${cfg.name}.age;
    networking.wireguard.interfaces.${cfg.name} = {
      ips = [ "10.66.30.26/32" "fc00:bbbb:bbbb:bb01::3:1e19/128" ];
      privateKeyFile = config.age.secrets.wg-torrent.path;
      peers = [{
        publicKey = mullvad_entry.pubkey;
        allowedIPs = [ "0.0.0.0/0" "::0/0" ];
        endpoint = "[${mullvad_entry.ipv6_addr_in}]:51820";
      }];
      interfaceNamespace = cfg.namespace;
      preSetup = ''
        ${pkgs.iproute2}/bin/ip netns add "${cfg.namespace}" || true
      '';
    };
    environment.etc."netns/torrent/resolv.conf".text = ''
      nameserver 10.64.0.1
    '';
  };
}
# todo: presets
