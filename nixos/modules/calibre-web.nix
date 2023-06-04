{ config, lib, pkgs, ... }:

let
  cfg = config.services.calibre-web;

  inherit (lib) mkIf optionalAttrs optionalString;

  concatMapAttrsStringsSep = sep: f: attrs: lib.concatStringsSep sep (lib.mapAttrsToList f attrs);

  toSQL = concatMapAttrsStringsSep ", " (key: value: "${key} = " + (if
    lib.isStringLike value then "'${value}'" else
      if value == false then "0" else toString value));
in
{
  options = with lib; {
    services.calibre-web = {
      enable = mkEnableOption (mdDoc "Calibre-Web");

      listen = {
        ip = mkOption {
          type = types.str;
          default = "::1";
          description = lib.mdDoc ''
            IP address that Calibre-Web should listen on.
          '';
        };

        port = mkOption {
          type = types.port;
          default = 8083;
          description = lib.mdDoc ''
            Listen port for Calibre-Web.
          '';
        };
      };

      dataDir = mkOption {
        type = types.str;
        default = "calibre-web";
        description = lib.mdDoc ''
          The directory below {file}`/var/lib` where Calibre-Web stores its data.
        '';
      };

      user = mkOption {
        type = types.str;
        default = "calibre-web";
        description = lib.mdDoc "User account under which Calibre-Web runs.";
      };

      group = mkOption {
        type = types.str;
        default = "calibre-web";
        description = lib.mdDoc "Group account under which Calibre-Web runs.";
      };

      openFirewall = mkOption {
        type = types.bool;
        default = false;
        description = lib.mdDoc ''
          Open ports in the firewall for the server.
        '';
      };

      options = {
        calibreLibrary = mkOption {
          type = types.nullOr types.path;
          default = null;
          description = lib.mdDoc ''
            Path to Calibre library.
          '';
        };

        enableBookConversion = mkOption {
          type = types.bool;
          default = false;
          description = lib.mdDoc ''
            Configure path to the Calibre's ebook-convert in the DB.
          '';
        };

        enableBookUploading = mkOption {
          type = types.bool;
          default = false;
          description = lib.mdDoc ''
            Allow books to be uploaded via Calibre-Web UI.
          '';
        };

        extraConfig = mkOption {
          type = types.attrsOf types.str;
          default = {};
          description = lib.mdDoc ''
            Additional settings to write to the DB.
          '';
        };

        reverseProxyAuth = {
          enable = mkOption {
            type = types.bool;
            default = false;
            description = lib.mdDoc ''
              Enable authorization using auth proxy.
            '';
          };

          header = mkOption {
            type = types.str;
            default = "";
            description = lib.mdDoc ''
              Auth proxy header name.
            '';
          };
        };
      };
    };
  };

  config = mkIf cfg.enable {
    systemd.services.calibre-web = let
      appDb = "/var/lib/${cfg.dataDir}/app.db";
      gdriveDb = "/var/lib/${cfg.dataDir}/gdrive.db";
      calibreWebCmd = "${pkgs.calibre-web}/bin/calibre-web -p ${appDb} -g ${gdriveDb}";

      settings = toSQL ({
        config_port = cfg.listen.port;
        config_uploading = cfg.options.enableBookUploading;
        config_allow_reverse_proxy_header_login = cfg.options.reverseProxyAuth.enable;
        config_reverse_proxy_login_header_name = cfg.options.reverseProxyAuth.header;
      } // optionalAttrs (cfg.options.calibreLibrary != null) {
        config_calibre_dir = cfg.options.calibreLibrary;
      } // optionalAttrs cfg.options.enableBookConversion {
        config_converterpath = "{pkgs.calibre}/bin/ebook-convert";
      } // cfg.options.extraConfig);
    in
      {
        description = "Web app for browsing, reading and downloading eBooks stored in a Calibre database";
        after = [ "network.target" ];
        wantedBy = [ "multi-user.target" ];
        preStart = ''
          __RUN_MIGRATIONS_AND_EXIT=1 ${calibreWebCmd}

          ${pkgs.sqlite}/bin/sqlite3 ${appDb} "update settings set ${settings}"
        '' + optionalString (cfg.options.calibreLibrary != null) ''
          test -f "${cfg.options.calibreLibrary}/metadata.db" || { echo "Invalid Calibre library"; exit 1; }
        '';

        serviceConfig = {
          Type = "simple";
          User = cfg.user;
          Group = cfg.group;

          StateDirectory = cfg.dataDir;
          ExecStart = "${calibreWebCmd} -i ${cfg.listen.ip}";
          Restart = "on-failure";
        };
      };

    networking.firewall = mkIf cfg.openFirewall {
      allowedTCPPorts = [ cfg.listen.port ];
    };

    users.users = mkIf (cfg.user == "calibre-web") {
      calibre-web = {
        isSystemUser = true;
        group = cfg.group;
      };
    };

    users.groups = mkIf (cfg.group == "calibre-web") {
      calibre-web = {};
    };
  };

  meta.maintainers = with lib.maintainers; [ pborzenkov ];
}
