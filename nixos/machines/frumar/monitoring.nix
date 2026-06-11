{ config, ... }:
{

  services.grafana = {
    enable = true;
    settings = {
      server.domain = "grafana.yori.cc";
      server.root_url = "https://grafana.yori.cc/";
      auth.oauth_allow_insecure_email_lookup = true;
      "auth.basic".enabled = false;
      "auth.google" = {
        enabled = true;
        allow_sign_up = false;
      };
      "auth.generic_oauth" = {
        enabled = true;
        name = "Pocket ID";
        icon = "https://pocket-id.yori.cc/api/application-images/logo";
        auth_url = "https://pocket-id.yori.cc/authorize";
        token_url = "https://pocket-id.yori.cc/api/oidc/token";
        allow_sign_up = true;
        use_pkce = true;
        # email_attribute_name = "email:primary";
        scopes = [
          "openid"
          "email"
          "profile"
        ];
        auth_style = "AutoDetect";
      };
      auth.disable_login_form = true;
      # 26.05 requires this to be set explicitly. This is the historical
      # nixpkgs default the DB secrets are already encrypted with; it only
      # protects datasource credentials at rest, which we don't store.
      # To rotate: put GF_SECURITY_SECRET_KEY in grafana.env and re-encrypt,
      # see https://github.com/erooke/grafana-secretkey-rotation-tool
      security.secret_key = "SW2YcwTIb9zpOOhoPsMm";
    };
  };
  services.victoriametrics = {
    enable = true;
    retentionPeriod = "1y";
    extraOptions = [ "-vmalert.proxyURL=http://127.0.0.1:8881" ];
  };
  services.victorialogs = {
    enable = true;
    extraOptions = [
      "-journald.streamFields=_HOSTNAME,_SYSTEMD_SLICE,_SYSTEMD_UNIT,SYSLOG_IDENTIFIER"
      "-memory.allowedPercent=10"
      "-retentionPeriod=14d"
      "-retention.maxDiskSpaceUsageBytes=10GiB"
    ];
  };

  services.prometheus.alertmanager = {
    enable = true;
    webExternalUrl = "http://127.0.0.1:9093";
    listenAddress = "127.0.0.1";
    port = 9093;
    configuration = {
      route = {
        receiver = "telegram";
        group_by = [ "alertname" ];
        group_wait = "30s";
        group_interval = "5m";
        repeat_interval = "12h";
      };
      receivers = [
        {
          name = "telegram";
          telegram_configs = [
            {
              bot_token_file = "/run/credentials/alertmanager.service/telegram";
              chat_id = 63609143;
              parse_mode = "HTML";
              send_resolved = true;
            }
          ];
        }
      ];
    };
  };
  systemd.services.alertmanager.serviceConfig.LoadCredential = [
    "telegram:${config.age.secrets.yobot-telegram.path}"
  ];

  services.vmalert.instances.main = {
    enable = true;
    settings = {
      "datasource.url" = "http://127.0.0.1:8428";
      "notifier.url" = [ "http://127.0.0.1:9093" ];
      "remoteWrite.url" = "http://127.0.0.1:8428";
      "remoteRead.url" = "http://127.0.0.1:8428";
      "httpListenAddr" = "127.0.0.1:8881";
      "external.label" = [ "host=frumar" ];
    };
    rules.groups = [
      {
        name = "host";
        rules = [
          {
            alert = "InstanceDown";
            expr = "up == 0";
            for = "5m";
            labels.severity = "critical";
            annotations.summary = "{{ $labels.instance }} ({{ $labels.job }}) is down";
          }
          {
            alert = "SystemdUnitFailed";
            expr = ''node_systemd_unit_state{state="failed"} == 1'';
            for = "5m";
            labels.severity = "warning";
            annotations.summary = "systemd unit {{ $labels.name }} failed on {{ $labels.instance }}";
          }
          {
            alert = "DiskFull";
            expr = ''100 - (node_filesystem_avail_bytes{fstype!~"tmpfs|overlay|ramfs"} / node_filesystem_size_bytes * 100) > 90'';
            for = "15m";
            labels.severity = "warning";
            annotations.summary = "{{ $labels.mountpoint }} on {{ $labels.instance }} is >90% full";
          }
          {
            alert = "HighLoad";
            expr = "node_load5 / count without (cpu, mode) (node_cpu_seconds_total{mode=\"idle\"}) > 2";
            for = "15m";
            labels.severity = "warning";
            annotations.summary = "load5 on {{ $labels.instance }} exceeds 2x cpu count";
          }
        ];
      }
    ];
  };
}
