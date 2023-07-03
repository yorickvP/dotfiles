{ pkgs, lib, config, ... }:
let cfg = config.services.yorick.torrent-vpn;
in {
  options.services.yorick.torrent-vpn = with lib; {
    enable = mkEnableOption "torrent-vpn";
    name = mkOption { type = types.str; };
    namespace = mkOption { type = types.str; };
  };
  config = lib.mkIf cfg.enable {
    age.secrets.wg-torrent.file = ../../secrets/wg.${cfg.name}.age;
    networking.wireguard.interfaces.${cfg.name} = {
      ips = [ "10.0.34.127/32" "2a0e:1c80:1337:1:10:0:34:127/128" ];
      privateKeyFile = config.age.secrets.wg-torrent.path;
      peers = [{
        publicKey = "W+LE+uFRyMRdYFCf7Jw0OPERNd1bcIm0gTKf/traIUk=";
        allowedIPs = [ "0.0.0.0/0" "::0/0" ];
        endpoint = "nl-ams.azirevpn.net:51820";
      }];
      interfaceNamespace = cfg.namespace;
      preSetup = ''
        ${pkgs.iproute2}/bin/ip netns add "${cfg.namespace}" || true
      '';
    };
    environment.etc."netns/torrent/resolv.conf".text = ''
      nameserver 91.231.153.2
      nameserver 192.211.0.2
      nameserver 2a0e:1c80:1337:1:10:0:0:1
    '';
  };
}
# todo: presets
