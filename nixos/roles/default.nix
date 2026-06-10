{
  config,
  pkgs,
  lib,
  name,
  inputs,
  ...
}:
let
  vpn = import ../vpn.nix;
in
{
  imports = [
    ./base.nix
    inputs.agenix.nixosModules.default
    inputs.disjoin.nixosModules.default
    ../modules/dk-vpn.nix
    ../modules/marvin-tracker.nix
    ../modules/muflax-blog.nix
    ../modules/nginx.nix
    ../modules/play-nijmegen-calendar.nix
    ../modules/nix-ci-puller.nix
    ../modules/selfsigned.nix
    ../modules/wg-restarter.nix
    ../modules/wpex.nix
    ../services
  ];
  age.secrets = {
    root-user-pass.file = ../../secrets/root-user-pass.age;
    yorick-user-pass.file = ../../secrets/yorick-user-pass.age;
    nix-netrc-yorick.file = ../../secrets/nix-netrc-yorick.age;
    wg.file = ../../secrets/wg.${name}.age;
  };

  networking.hostName = name;

  users.users = {
    # root password is useful from console, ssh has password logins disabled
    root.hashedPasswordFile = config.age.secrets.root-user-pass.path; # TODO: generate own
    yorick.hashedPasswordFile = config.age.secrets.yorick-user-pass.path;
  };

  environment.systemPackages =
    with pkgs;
    [
      pciutils
      usbutils
      smartmontools
      hdparm
      lm_sensors
      nvme-cli
    ]
    ++ lib.optional (builtins.elem "kvm-amd" config.boot.kernelModules) pkgs.amdgpu_top;

  nix.gc.automatic = true;

  networking.wireguard.interfaces.wg-y = {
    privateKeyFile = config.age.secrets.wg.path;
    ips = [ vpn.ips.${name} ];
    listenPort = 31790;
    peers = lib.mapAttrsToList (peer: publicKey: {
      inherit publicKey;
      endpoint = "pennyworth.yori.cc:40000";
      allowedIPs = [ "${vpn.ips.${peer}}/32" ];
      persistentKeepalive = 30;
    }) (lib.filterAttrs (peer: _: peer != name) vpn.keys);
    postSetup = "ip link set dev wg-y mtu 1371";
  };
  services.wg-restarter = {
    enable = true;
    gateway = "10.209.0.1";
    service = "wireguard-wg-y";
  };

  security.acme = {
    defaults.email = "acme@yori.cc";
    acceptTerms = true;
  };

  services.openssh.extraConfig = lib.mkIf (builtins.pathExists ../../host_keys/${name}-cert.pub) ''
    HostCertificate ${../../host_keys/${name}-cert.pub}
  '';

  programs.ssh.knownHosts."yorick-ca-host" = {
    certAuthority = true;
    publicKey = "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIBuVsdrB/TRj3KC7Kofh0REDNW6Xa9QO0AnjPejC1b6kAAAABHNzaDo= yorick-ca-host";
    hostNames = [
      "*.yori.cc"
      "10.209.0.*"
      "10.100.0.*"
    ];
  };

  services.prometheus.exporters = {
    node = {
      enable = true;
      enabledCollectors = [ "systemd" ];
      disabledCollectors = [ "rapl" ];
    };
    zfs.enable = config.boot.zfs.enabled;
    wireguard.enable = true;
    # unpoller
    # smartctl.enable = true;
    # rasdaemon.enable = true; # todo: only frumar
    # postgres
    # nvidia-gpu
    # nginx
    # nats
    # mail
    # ipmi
    # exportarr
    # dovecot & postfix
    # dmarc
    # transmission

  };
  networking.firewall.interfaces.wg-y.allowedTCPPorts = [ 9100 ];
  # go away, teams!
  xdg.autostart.enable = lib.mkForce false;

  nix.settings = {
    substituters = [ "https://cache.yori.cc/yorick" ];
    netrc-file = config.age.secrets.nix-netrc-yorick.path;
    trusted-public-keys = [
      "yorick:sWqvIllvDhMS9vcWyk4+zSk9L6zq8UgcLPEEQJsAdW4="
    ];
  };

  services.journald.upload = {
    enable = true;
    settings.Upload = {
      URL = "http://localhost:9429/insert/journald";
      NetworkTimeoutSec = "5min";
    };
  };
  services.vlagent = {
    enable = true;
    remoteWrite = {
      url = "http://frumar.vpn.yori.cc:9428/internal/insert";
      # https://github.com/NixOS/nixpkgs/pull/510600
      # maxDiskUsagePerUrl = "500MB";
    };
    extraArgs = [
      "-remoteWrite.maxDiskUsagePerURL=500MB"
      "-remoteWrite.showURL"
      "-journald.streamFields=_HOSTNAME,_SYSTEMD_SLICE,_SYSTEMD_UNIT,SYSLOG_IDENTIFIER"
    ];
  };
  services.vmagent = {
    enable = true;
    remoteWrite.url = "http://frumar.vpn.yori.cc:8428/api/v1/write";
    extraArgs = [
      "-remoteWrite.showURL"
      "-remoteWrite.maxDiskUsagePerURL=500MB"
    ];
    prometheusConfig = {
      global.external_labels.instance = name;
      scrape_configs =
        let
          simpleJob = job_name: target: service: {
            inherit job_name;
            static_configs = if service.enable then [ { targets = [ target ]; } ] else [ ];
          };
          exporterJob =
            job_name:
            let
              service = config.services.prometheus.exporters.${job_name};
              target = "localhost:${toString service.port}";
            in
            simpleJob job_name target service;
        in
        with config.services;
        [
          (simpleJob "vmagent" "localhost:8429" vmagent)
          (simpleJob "victoriametrics" "localhost:8428" victoriametrics)
          (simpleJob "victorialogs" "localhost:9428" victorialogs)
          (simpleJob "vlagent" "localhost:9429" vlagent)
          (exporterJob "node")
          (exporterJob "zfs")
          (exporterJob "wireguard")
        ];
    };
  };
  programs.msmtp.accounts.default = {
    auth = true;
    tls = true;
    from = "${name}@yori.cc";
    host = "pennyworth.yori.cc";
    user = "${name}@yori.cc";
    passwordeval = "${pkgs.coreutils}/bin/cat ${config.age.secrets.msmtp-mail-pass.path}";
  };
  services.smartd.notifications.mail = {
    sender = "${name}@yori.cc";
    recipient = "yorickvanpelt@gmail.com";
  };
  services.znapzend = {
    pure = true;
    features = {
      zfsGetType = true;
      sendRaw = true;
    };
  };

  services.zfs = {
    autoScrub = {
      enable = true;
      interval = "*-*-01 02:00:00"; # monthly + 2 hours
    };
    trim.enable = true;
    zed.settings = {
      ZED_EMAIL_ADDR = [ "yorickvanpelt@gmail.com" ];
      ZED_NOTIFY_INTERVAL_SECS = 3600;
      ZED_NOTIFY_VERBOSE = true;
      ZED_SCRUB_AFTER_RESILVER = true;
    };
  };
  services.nix-ci-puller = {
    enable = true;
    topics = [
      "yorick/git/dotfiles/main/${name}"
    ];
    allowedSSIDs = [ "hope clouds observation" ];
  };
}
