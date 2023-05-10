{ lib, ... }: {
  systemd.services.nginx.serviceConfig = {
    ProtectHome = "tmpfs";
    UMask = lib.mkForce "0022";
    BindReadOnlyPaths = [ "/home/dk-stage/out" ];
  };
  systemd.tmpfiles.rules = [
    "d /home/dk-stage 755 dk-stage dk-stage"
    "d /home/dk-stage/out 755 dk-stage dk-stage"
  ];
  users.users.dk-stage = {
    home = "/home/dk-stage";
    group = "dk-stage";
    useDefaultShell = true;
    isSystemUser = true;
    openssh.authorizedKeys.keys = with (import ../sshkeys.nix); [
      ''command="rsync --server -logDtprcze.iLsfxCIvu --log-format=X --delete --partial . out/" ${dk-stage-deploy}''
    ];
    createHome = false; # sets wrong permissions
  };
  users.groups.dk-stage = { };
  services.nginx.virtualHosts."dk-stage.yori.cc" = {
    forceSSL = true;
    enableACME = true;
    locations."/" = {
      root = "/home/dk-stage/out";
      index = "index.html";
      extraConfig = ''
        error_page 404 /404.html;
      '';
    };
  };
}
