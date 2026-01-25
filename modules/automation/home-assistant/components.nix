# Home Assistant Component Wiring
#
# Maps component options to customComponents, extraComponents, and customLovelaceModules.
# Also contains component-specific HA YAML configuration.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.mares.home-assistant;
  cmp = cfg.components;
  python = pkgs.home-assistant.python;

  # Local packages (in packages/home-assistant/)
  packages = {
    meross-lan = pkgs.callPackage ../../../packages/home-assistant/meross-lan.nix { };
    evcc = pkgs.callPackage ../../../packages/home-assistant/evcc.nix { };
    syr-connect = pkgs.callPackage ../../../packages/home-assistant/syr-connect.nix {
      inherit (python.pkgs) pycryptodomex;
    };
    scrypted = pkgs.callPackage ../../../packages/home-assistant/scrypted.nix { };
    homeconnect-local = pkgs.callPackage ../../../packages/home-assistant/homeconnect-local.nix {
      inherit (python.pkgs)
        buildPythonPackage
        fetchPypi
        setuptools
        versioningit
        aiohttp
        xmltodict
        pycryptodome
        ;
    };
    ostrom = python.pkgs.callPackage ../../../packages/home-assistant/ostrom.nix { };
  };

  # Helper functions
  enabled = name: cmp.${name}.enable;
  optional = name: value: lib.optional (enabled name) value;

  # Custom components (local packages)
  localComponents = lib.concatLists [
    (optional "meross-lan" packages.meross-lan)
    (optional "evcc" packages.evcc)
    (optional "syr-connect" packages.syr-connect)
    (optional "scrypted" packages.scrypted)
    (optional "home-connect-local" packages.homeconnect-local)
    (optional "ostrom" packages.ostrom)
  ];

  # Custom components (nixpkgs)
  nixpkgsComponents = lib.concatLists [
    (optional "scene-presets" pkgs.home-assistant-custom-components.scene_presets)
    (optional "home-connect-alt" pkgs.home-assistant-custom-components.home_connect_alt)
    (optional "waste-collection-schedule" pkgs.home-assistant-custom-components.waste_collection_schedule)
  ];

  # Base HA components (always enabled)
  baseComponents = [
    "default_config"
    "isal"
    "mqtt"
    "open_meteo"
    "dwd_weather_warnings"
    "mobile_app"
    "prometheus"
    "ipp"
    "google_translate"
    "hue"
    "apple_tv"
    "unifiprotect"
    "local_calendar"
  ];

  # Optional built-in HA components
  optionalBuiltinComponents = lib.concatLists [
    (optional "shelly" "shelly")
    (optional "influxdb" "influxdb")
    (optional "homekit" "homekit")
    (optional "fronius" "fronius")
    (optional "samsung-tv" "samsungtv")
    (optional "roborock" "roborock")
  ];

  # Lovelace modules
  lovelaceModules = lib.concatLists [
    (optional "apexcharts" pkgs.home-assistant-custom-lovelace-modules.apexcharts-card)
  ];
in
{
  config = lib.mkIf cfg.enable {
    services.home-assistant = {
      customComponents = localComponents ++ nixpkgsComponents;
      customLovelaceModules = lovelaceModules;
      extraComponents = baseComponents ++ cfg.extraComponents ++ optionalBuiltinComponents;

      # Integration-specific HA YAML config
      config = lib.mkMerge [
        # InfluxDB config
        (lib.mkIf cmp.influxdb.enable {
          influxdb = {
            api_version = 2;
            ssl = false;
            host = cmp.influxdb.host;
            port = cmp.influxdb.port;
            organization = cmp.influxdb.organization;
            bucket = cmp.influxdb.bucket;
            token = "!secret influxdb_token";
            max_retries = cmp.influxdb.maxRetries;
            include.entity_globs = [ "sensor.*" ];
          };
        })

        # HomeKit config
        (lib.mkIf cmp.homekit.enable {
          homekit = [
            {
              name = "Mares HomeKit Bridge";
              port = 21063;
              filter = {
                include_domains = [
                  "cover"
                  "light"
                  "switch"
                ];
                exclude_domains = [
                  "automation"
                  "media_player"
                  "script"
                ];
              };
            }
          ];
        })
      ];
    };

    # Firewall for HomeKit
    networking.firewall.allowedTCPPorts = lib.mkIf (cfg.openFirewall && cmp.homekit.enable) [ 21063 ];
  };
}
