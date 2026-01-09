{ lib, ... }:
let
  inherit (lib) mkEnableOption mkOption types;
in
{
  options.mares.home-assistant = {
    enable = mkEnableOption "Home Assistant";

    openFirewall = mkOption {
      type = types.bool;
      default = true;
      description = "Whether to open the firewall for the Home Assistant port.";
    };

    port = mkOption {
      type = types.port;
      default = 8123;
      description = "Port for Home Assistant web interface.";
    };

    configDir = mkOption {
      type = types.str;
      default = "/var/lib/hass";
      description = "Home Assistant configuration directory.";
    };

    bindAddress = mkOption {
      type = types.str;
      description = "IP address to bind the Home Assistant web interface to.";
    };

    trustedProxies = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "List of trusted proxy IP addresses for X-Forwarded-For headers.";
    };

    extraComponents = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "Additional Home Assistant components to enable.";
    };

    recorder = {
      purgeKeepDays = mkOption {
        type = types.int;
        default = 14;
        description = "Number of days to keep recorder history.";
      };

      commitInterval = mkOption {
        type = types.int;
        default = 1;
        description = "How often to commit recorder data (in seconds).";
      };

      excludeDomains = mkOption {
        type = types.listOf types.str;
        default = [
          "automation"
          "updater"
        ];
        description = "Domains to exclude from recorder.";
      };
    };

    influxdb = {
      enable = mkEnableOption "InfluxDB integration for long-term history";

      host = mkOption {
        type = types.str;
        default = "";
        description = "InfluxDB host.";
      };

      port = mkOption {
        type = types.port;
        default = 8086;
        description = "InfluxDB port.";
      };

      organization = mkOption {
        type = types.str;
        default = "mares";
        description = "InfluxDB organization.";
      };

      bucket = mkOption {
        type = types.str;
        default = "home-assistant";
        description = "InfluxDB bucket.";
      };

      maxRetries = mkOption {
        type = types.int;
        default = 3;
        description = "Maximum retries for InfluxDB writes.";
      };
    };

    shelly = {
      enable = mkEnableOption "Shelly integration (native + Gen2+ MQTT discovery)";

      deviceIds = mkOption {
        type = types.listOf types.str;
        default = [ ];
        example = [
          "shellyplus2pm-485519a1ff8c"
          "shellyplusht-abcdef123456"
        ];
        description = ''
          List of Shelly Gen2+ device IDs for the announce automation.
          Required for battery-powered devices that need to be poked to announce themselves.
          Device IDs can be found in the Shelly device web UI or via MQTT topics.
        '';
      };
    };

    meross = {
      enable = mkEnableOption "Meross LAN integration";
    };

    homekit = {
      enable = mkEnableOption "HomeKit Bridge integration";
    };

    scenePresets = {
      enable = mkEnableOption "Scene Presets - Hue-like color picker for lights";
    };
  };
}
