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
    };
  };
  services.victoriametrics = {
    enable = true;
    retentionPeriod = "1y";
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
}
