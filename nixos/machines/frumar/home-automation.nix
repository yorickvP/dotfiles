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
    };
  };
  services.home-assistant = {
    enable = true;
    openFirewall = true;
    extraComponents = [
      "default_config"
      "androidtv"
      "esphome"
      "met"
      "unifi" "yeelight" "plex" "frontend"
      "tado"
      "automation" "device_automation"
      "homewizard"
      "github" "backup"
      "mqtt"
      "brother"
      "spotify"
      "yamaha_musiccast"
      "ipp"
      "homekit_controller"
      "tuya" "ffmpeg"
      #"unifiprotect"
    ];
    config = {
      mobile_app = {};
      default_config = {};
      system_log = {};
      "map" = {};
      
      frontend.themes = "!include_dir_merge_named themes";
      automation = "!include automations.yaml";
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
    };
  };
}
