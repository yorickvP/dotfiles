{
  config,
  pkgs,
  lib,
  ...
}:

let
  sslForward =
    proxyPass: extra:
    lib.mkMerge [
      {
        onlySSL = true;
        quic = true;
        useACMEHost = "wildcard.yori.cc";
        locations."/" = {
          inherit proxyPass;
          proxyWebsockets = true;
        };
      }
      extra
    ];
in

{
  security.y-selfsigned.enable = true;
  services.yorick.cert."wildcard.yori.cc".enable = true;

  services.nginx = {
    enable = true;
    virtualHosts = {
      "unifi.yori.cc" = sslForward "https://[::1]:8443" {
        locations."/".extraConfig = ''
          proxy_ssl_verify off;
          proxy_ssl_session_reuse on;
        '';
      };
      "grafana.yori.cc" = sslForward "http://127.0.0.1:3000" { };
      "prometheus.yori.cc" = sslForward "http://127.0.0.1:8428" {
        # only over VPN
        listen = [
          {
            addr = "10.209.0.3";
            port = 443;
            ssl = true;
          }
        ];
      };
      "plex.yori.cc" = sslForward "http://127.0.0.1:32400" {
        extraConfig = ''
          gzip on;
          gzip_vary on;
          gzip_min_length 1000;
          gzip_proxied any;
          gzip_types text/plain text/css text/xml application/xml text/javascript application/x-javascript image/svg+xml;
          proxy_http_version 1.1;
          proxy_buffering off;
        '';
      };
      "immich.yori.cc" = sslForward "http://[::1]:2283" {
        extraConfig = ''
          client_max_body_size 50000M;
          proxy_request_buffering off;
          client_body_buffer_size 1024k;
          proxy_read_timeout 600s;
          proxy_send_timeout 600s;
          send_timeout 600s;
        '';
      };
      "priv.yori.cc" =
        let
          oauth2Block = ''
            # pass information via X-User and X-Email headers to backend,
            # requires running with --set-xauthrequest flag
            auth_request_set $user   $upstream_http_x_auth_request_user;
            auth_request_set $email  $upstream_http_x_auth_request_email;
            auth_request_set $auth_cookie $upstream_http_set_cookie;

            proxy_set_header X-User  $user;
            proxy_set_header X-Email $email;

            # if you enabled --cookie-refresh, this is needed for it to work with auth_request
            add_header Set-Cookie $auth_cookie;
          '';
          proxyOauth2 = proxyPass: {
            inherit proxyPass;
            extraConfig = oauth2Block;
          };
        in
        {
          onlySSL = true;
          useACMEHost = "wildcard.yori.cc";
          locations."/".root = pkgs.writeTextDir "index.html" ''
            <!DOCTYPE HTML>
            <ul>
            <li><a href="/paperless/">paperless</a>
            <li><a href="/sonarr/">sonarr</a>
            <li><a href="/radarr/">radarr</a>
            <li><a href="/transmission/">transmission</a>
            <li><a href="/victorialogs/select/vmui">victorialogs</a>
            <li><a href="/oauth2/sign_out?rd=/">sign out</a>
            </ul>
          '';
          locations."/sonarr" = proxyOauth2 "http://127.0.0.1:8989";
          locations."/radarr" = proxyOauth2 "http://127.0.0.1:7878";
          locations."/marvin-tracker/" = {
            proxyPass = "http://[::1]:${toString config.services.yorick.marvin-tracker.port}/";
            extraConfig = "auth_request off;";
            # handles auth using arg
          };
          locations."/paperless/" = lib.mkMerge [
            (proxyOauth2 "http://127.0.0.1:${toString config.services.paperless.port}/")
            {
              extraConfig = ''
                more_set_headers "X-Frame-Options: SAMEORIGIN";
              '';
            }
          ];
          locations."/transmission/" = proxyOauth2 "http://unix:/torrent/sockets/transmission.sock";
          locations."/transmission/rpc" = lib.mkMerge [
            (proxyOauth2 "http://unix:/torrent/sockets/transmission.sock")
            { extraConfig = "auth_request off;"; }
          ];
          locations."/victorialogs/" = proxyOauth2 "http://127.0.0.1:9428/";
        };
      "frumar.yori.cc" = {
        enableACME = lib.mkForce false;
        inherit (config.security.y-selfsigned) sslCertificate sslCertificateKey;
      };
    };
  };
  systemd.services.nginx.serviceConfig.BindReadOnlyPaths = [
    "/torrent/sockets"
  ];

  services.oauth2-proxy = {
    enable = true;
    email.addresses = "yorickvanpelt@gmail.com";
    redirectURL = "https://priv.yori.cc/oauth2/callback";
    reverseProxy = true;
    keyFile = config.age.secrets.oauth2-proxy.path;
    setXauthrequest = true;
    nginx.virtualHosts."priv.yori.cc" = {
      allowed_emails = [ "yorickvanpelt@gmail.com" ];
    };
    nginx.domain = "priv.yori.cc";
    provider = "oidc";
    scope = "openid email profile groups";
    extraConfig = {
      whitelist-domain = [ "priv.yori.cc" ];
      code-challenge-method = "S256";
      oidc-issuer-url = "https://pocket-id.yori.cc";
      login-url = "https://pocket-id.yori.cc/authorize";
      redeem-url = "https://pocket-id.yori.cc/api/oidc/token";
      oidc-jwks-url = "https://pocket-id.yori.cc/.well-known/jwks.json";
      profile-url = "https://pocket-id.yori.cc/api/oidc/userinfo";
      skip-oidc-discovery = true;
    };
  };
}
