{ config, pkgs, lib, ... }: {
  services.nginx.virtualHosts."home-assistant.yori.cc" = {
    onlySSL = true;
    useACMEHost = "wildcard.yori.cc";
    locations."/" = {
      proxyPass = "http://[::1]:8123";
      proxyWebsockets = true;
    };
  };
  services.zigbee2mqtt = {
    enable = true;
    settings = {
      availability = true;
      device_options.legacy = false;
      serial.port = "/dev/ttyUSB0";
      frontend = {
        port = 8081;
        url = "http://frumar.vpn.yori.cc:8081";
      };
    };
  };
  age.secrets.govee2mqtt-env.file = ../../../secrets/govee2mqtt.env.age;
  services.govee2mqtt = {
    enable = true;
    environmentFile = config.age.secrets.govee2mqtt-env.path;
  };
  systemd.services.govee2mqtt.serviceConfig = {
    RestartSec = 2;
    RestartSteps = 10;
    RestartMaxDelaySec = 60;
  };
  networking.firewall.allowedUDPPorts = [ 4002 ]; # govee2mqtt
  networking.firewall.interfaces.wg-y.allowedTCPPorts = [ 8081 ];
  services.home-assistant = {
    enable = true;
    openFirewall = true;
    extraComponents = [
      "default_config"
      "androidtv"
      "androidtv_remote"
      "esphome"
      "met"
      "unifi" "yeelight" "plex" "frontend"
      "tado"
      "automation" "device_automation"
      "homewizard"
      "github" "backup"
      "mqtt"
      "brother"
      "utility_meter"
      "spotify"
      "yamaha_musiccast" "cast"
      "ipp"
      "homekit_controller"
      "tuya" "ffmpeg"
      "govee_light_local"
      #"unifiprotect"
    ];
    customComponents = [
      (pkgs.buildHomeAssistantComponent rec {
        owner = "georgezhao2010";
        domain = "midea_ac_lan";
        version = "0.3.22";
        src = pkgs.fetchFromGitHub {
          inherit owner;
          repo = domain;
          rev = "v${version}";
          hash = "sha256-xTnbA4GztHOE61QObEJbzUSdbuSrhbcJ280DUDdM+n4=";
        };
      })
      (pkgs.buildHomeAssistantComponent rec {
        owner = "rospogrigio";
        domain = "localtuya";
        version = "5.2.1";
        src = pkgs.fetchFromGitHub {
          owner = "rospogrigio";
          repo = "localtuya";
          rev = "v${version}";
          hash = "sha256-hA/1FxH0wfM0jz9VqGCT95rXlrWjxV5oIkSiBf0G0ac=";
        };
      })
      # todo: adaptive-lighting?
    ];
    config = {
      mobile_app = {};
      default_config = {};
      system_log = {};
      
      frontend.themes = "!include_dir_merge_named themes";
      frontend.extra_module_url = "/local/card-mod.js";
      automation = "!include automations.yaml";
      script = "!include scripts.yaml";
      scene = "!include scenes.yaml";
      homeassistant = {
        name = "Home";
        latitude = "51.84";
        longitude = "5.85";
        elevation = "0";
        unit_system = "metric";
        time_zone = "Europe/Amsterdam";
        country = "NL";
      };
      http = {
        use_x_forwarded_for = true;
        trusted_proxies = [ "::1" ];
      };
      lovelace = {
        mode = "storage";
        dashboards = "!include dashboards.yaml";
      };
    };
  };
}
