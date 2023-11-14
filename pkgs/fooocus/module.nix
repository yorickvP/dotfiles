{ config, lib, pkgs, ... }:
let cfg = config.services.fooocus; in
{
  options.services.fooocus = with lib; {
    enable = mkEnableOption "Fooocus";
    package = mkOption {
      type = types.package;
      description = "The package name of the Fooocus server";
      default = pkgs.fooocus;
    };
    port = mkOption {
      type = types.int;
      description = "The port to run the Fooocus server on";
      default = 7860;
    };
    listen = mkOption {
      type = types.str;
      description = "The address to listen on";
      default = "127.0.0.1";
    };
    path = {
      models = mkOption {
        type = types.path;
        description = "The path to the models directory";
        default = "/var/models/Fooocus/models";
      };
      outputs = mkOption {
        type = types.path;
        description = "The path to the outputs directory";
        default = "/var/sd/outputs/sdxl";
      };
      checkpoints = mkOption {
        type = types.path;
        description = "The path to the checkpoints directory";
        default = "${cfg.path.models}/checkpoints";
      };
      loras = mkOption {
        type = types.path;
        description = "The path to the loras directory";
        default = "${cfg.path.models}/loras";
      };
      embeddings = mkOption {
        type = types.path;
        description = "The path to the embeddings directory";
        default = "${cfg.path.models}/embeddings";
      };
      vae_approx = mkOption {
        type = types.path;
        description = "The path to the vae_approx directory";
        default = "${cfg.path.models}/vae_approx";
      };
      upscale_models = mkOption {
        type = types.path;
        description = "The path to the upscale_models directory";
        default = "${cfg.path.models}/upscale_models";
      };
      inpaint = mkOption {
        type = types.path;
        description = "The path to the inpaint directory";
        default = "${cfg.path.models}/inpaint";
      };
      controlnet = mkOption {
        type = types.path;
        description = "The path to the controlnet directory";
        default = "${cfg.path.models}/controlnet";
      };
      clip_vision = mkOption {
        type = types.path;
        description = "The path to the clip_vision directory";
        default = "${cfg.path.models}/clip_vision";
      };
      fooocus_expansion = mkOption {
        type = types.path;
        description = "The path to the fooocus_expansion directory";
        default = "${cfg.path.models}/prompt_expansion/fooocus_expansion";
      };
    };
    config = mkOption {
      type = types.attrsOf types.str;
      description = "The configuration for the Fooocus server";
      default = {
        "path_checkpoints" = "${cfg.path.checkpoints}";
        "path_loras" = "${cfg.path.loras}";
        "path_embeddings" = "${cfg.path.embeddings}";
        "path_vae_approx" = "${cfg.path.vae_approx}";
        "path_upscale_models" = "${cfg.path.upscale_models}";
        "path_inpaint" = "${cfg.path.inpaint}";
        "path_controlnet" = "${cfg.path.controlnet}";
        "path_clip_vision" = "${cfg.path.clip_vision}";
        "path_fooocus_expansion" = "${cfg.path.fooocus_expansion}";
        "path_outputs" = "${cfg.path.outputs}";
      };
    };
      
  };
  config = let
    configFile = pkgs.writeText "config.json" (builtins.toJSON cfg.config);
  in lib.mkIf cfg.enable {
    systemd.services.fooocus = {
      description = "Fooocus server";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "simple";
        # it wants to write for no good reason
        # todo: remove these symlinks
        ExecStartPre = pkgs.writeShellScript "pre-start" ''
          cp ${configFile} /var/lib/fooocus/config.txt
          chmod +w /var/lib/fooocus/config.txt
          mkdir /tmp/fooocus
          ln -sfn ${cfg.package}/javascript /var/lib/fooocus/javascript
          ln -sfn ${cfg.package}/css /var/lib/fooocus/css
        '';
        ExecStart = "${cfg.package}/webui.py --port ${toString cfg.port} --disable-auto-launch --listen ${cfg.listen}";
        Restart = "always";
        RestartSec = "10";
        User = "fooocus";
        Group = "fooocus";
        PrivateTmp = true;
        ProtectSystem = "full";
        ProtectHome = true;
        NoNewPrivileges = true;
        WorkingDirectory = "/var/lib/fooocus";
        ReadWritePaths = [
          "/var/lib/fooocus"
          "/var/models/Fooocus"
          "/var/sd/outputs/sdxl"
        ];
      };
    };
    users.users.fooocus = {
      isSystemUser = true;
      createHome = true;
      group = "fooocus";
      home = "/var/lib/fooocus";
    };
    users.groups.fooocus = {};
  };
}
