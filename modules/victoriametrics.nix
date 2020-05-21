{ config, pkgs, lib, ... }:
let cfg = config.services.victoriametrics; in
{
  options.services.victoriametrics = with lib; {
    enable = mkEnableOption "victoriametrics";
    package = mkOption {
      type = types.package;
      default = pkgs.victoriametrics;
      defaultText = "pkgs.victoriametrics";
      description = ''
        The VictoriaMetrics distribution to use.
      '';
    };
    http = mkOption {
      default = ":8428";
      type = types.str;
      description = ''
        The listen address for the http interface.
      '';
    };
    retentionPeriod = mkOption {
      type = types.int;
      default = 1;
      description = ''
        Retention period in months.
      '';
    };
    extraOptions = mkOption {
      type = types.listOf types.str;
      default = [];
      description = ''
        Extra options to pass to VictoriaMetrics. See
        the README or victoriametrics -help for more
        information.
      '';
    };
  };
  config = lib.mkIf cfg.enable {
    systemd.services.victoriametrics = {
      description = "VictoriaMetrics time series database";
      serviceConfig = {
        StateDirectory = "victoriametrics";
        DynamicUser = true;
        ExecStart = "${cfg.package}/bin/victoria-metrics -storageDataPath=/var/lib/victoriametrics -httpListenAddr ${cfg.http} -retentionPeriod ${toString cfg.retentionPeriod} ${lib.concatStringsSep " " cfg.extraOptions}";
      };
      wantedBy = [ "multi-user.target" ];
    };
  };
}
