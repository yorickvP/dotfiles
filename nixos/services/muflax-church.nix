{ config, lib, pkgs, ... }:

let
  muflax-source = builtins.fetchGit {
    rev = "e5ce7ae4296c6605a7e886c153d569fc38318096";
    ref = "HEAD";
    url = "https://github.com/fmap/muflax65ngodyewp.onion.git";
  };
  nixpkgs = import (builtins.fetchTarball {
    url =
      "https://github.com/NixOS/nixpkgs-channels/archive/78e9665b48ff45d3e29f45b3ebeb6fc6c6e19922.tar.gz";
    sha256 = "09f50jaijvry9lrnx891qmcf92yb8qs64n1cvy0db2yjrmxsxyw8";
  }) { system = pkgs.stdenv.system; };
  muflax-church =
    (nixpkgs.callPackage "${muflax-source}/maintenance" { }).overrideDerivation
    (default: {
      buildPhase = default.buildPhase + "\n" + ''
        grep -lr '[^@]muflax.com' out | xargs -r sed -i 's/\([^@]\)muflax.com/\1muflax.church/g;s/http:\/\/\([^@]*\)muflax.church/https:\/\/\1muflax.church/g'
      '';
    });
  cfg = config.services.yorick.muflax-church;
  inherit (cfg) vhost;
  addrs = {
    "daily.${vhost}" = "${muflax-church}/daily";
    "blog.${vhost}" = "${muflax-church}/blog";
    "gospel.${vhost}" = "${muflax-church}/gospel";
    "alt.${vhost}" = "/home/public/public/muflax";
  };
  m = x: root: {
    forceSSL = true;
    useACMEHost = vhost;
    inherit root;
  };
in {
  options.services.yorick.muflax-church = with lib; {
    enable = mkEnableOption "muflax.church";
    vhost = mkOption { type = types.str; };
  };
  config = lib.mkIf cfg.enable {
    services.nginx.virtualHosts = {
      ${cfg.vhost} = {
        forceSSL = true;
        enableACME = true;
        root = "${muflax-church}/muflax";
      };
      "daily.${vhost}" = m "${muflax-church}/daily";
      "blog.${vhost}" = m "${muflax-church}/blog";
      "gospel.${vhost}" = m "${muflax-church}/gospel";
      "alt.${vhost}" = m "/home/public/public/muflax";
    } // (lib.mapAttrs m addrs);
    security.acme.certs.${vhost}.extraDomainNames =
      [ "daily.${vhost}" "blog.${vhost}" "gospel.${vhost}" "alt.${vhost}" ];
  };
}
