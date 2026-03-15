{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

let
  muflax-church =
    inputs.muflax-blog.packages.${pkgs.stdenv.system}.default.overrideAttrs
      (old: {
        buildPhase =
          old.buildPhase
          + "\n"
          + ''
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
in
{
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
    }
    // (lib.mapAttrs m addrs);
    security.acme.certs.${vhost}.extraDomainNames = [
      "daily.${vhost}"
      "blog.${vhost}"
      "gospel.${vhost}"
      "alt.${vhost}"
    ];
  };
}
