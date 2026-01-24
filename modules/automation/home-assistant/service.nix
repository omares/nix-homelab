# Home Assistant Core Service Configuration
#
# This file contains the core HA service setup: http, recorder, zones, etc.
# Automations and scenes are in automations.nix
# Shelly discovery is in shelly.nix
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.mares.home-assistant;
  python = pkgs.home-assistant.python;
  format = pkgs.formats.yaml { };

  merossLan = pkgs.callPackage ./meross-lan.nix { };
  haEvcc = pkgs.callPackage ./ha-evcc.nix { };
  syrConnect = pkgs.callPackage ./syr-connect.nix {
    inherit (python.pkgs) pycryptodomex;
  };
  haScrypted = pkgs.callPackage ./ha-scrypted.nix { };
  homeConnectLocal = pkgs.callPackage ./homeconnect-local.nix {
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
  ostrom = python.pkgs.callPackage ./ostrom.nix { };

  merossComponents = lib.optionals cfg.meross.enable [ merossLan ];
  scenePresetsComponents = lib.optionals cfg.scenePresets.enable [
    pkgs.home-assistant-custom-components.scene_presets
  ];
  evccComponents = lib.optionals cfg.evcc.enable [ haEvcc ];
  syrConnectComponents = lib.optionals cfg.syrConnect.enable [ syrConnect ];
  scryptedComponents = lib.optionals cfg.scrypted.enable [ haScrypted ];
  homeConnectLocalComponents = lib.optionals cfg.homeConnectLocal.enable [ homeConnectLocal ];
  homeConnectAltComponents = lib.optionals cfg.homeConnectAlt.enable [
    pkgs.home-assistant-custom-components.home_connect_alt
  ];
  wasteCollectionScheduleComponents = lib.optionals cfg.wasteCollectionSchedule.enable [
    pkgs.home-assistant-custom-components.waste_collection_schedule
  ];
  ostromComponents = lib.optionals cfg.ostrom.enable [ ostrom ];

  # Mares Home dashboard with ApexCharts for energy price visualization
  maresHomeDashboard = format.generate "mares-home.yaml" {
    title = "Mares Home";
    views = [
      {
        title = "Energy";
        path = "energy";
        icon = "mdi:lightning-bolt";
        cards = [
          {
            type = "custom:apexcharts-card";
            graph_span = "24h";
            header = {
              title = "Strompreise (€/kWh)";
              show = true;
            };
            apex_config = {
              xaxis = {
                type = "datetime";
                labels.datetimeFormatter = {
                  hour = "HH:mm";
                  day = "dd MMM";
                };
              };
              plotOptions.bar.colors.ranges = [
                {
                  from = 0;
                  to = 0.15;
                  color = "#2ecc71";
                }
                {
                  from = 0.15;
                  to = 0.2;
                  color = "#a6d96a";
                }
                {
                  from = 0.2;
                  to = 0.25;
                  color = "#ffff99";
                }
                {
                  from = 0.25;
                  to = 0.3;
                  color = "#fdae61";
                }
                {
                  from = 0.3;
                  to = 0.35;
                  color = "#f46d43";
                }
                {
                  from = 0.35;
                  to = 1;
                  color = "#d73027";
                }
              ];
            };
            series = [
              {
                entity = "sensor.ostrom_energy_spot_price";
                type = "column";
                name = "Preis";
                float_precision = 3;
                group_by = {
                  duration = "1h";
                  func = "avg";
                };
                show = {
                  datalabels = false;
                  in_header = false;
                };
              }
            ];
            yaxis = [
              {
                min = 0;
                max = 0.5;
              }
            ];
          }
          {
            type = "custom:apexcharts-card";
            graph_span = "23h";
            span = {
              start = "hour";
              offset = "-1h";
            };
            header = {
              title = "Strompreise Zukunft (€/kWh)";
              show = true;
            };
            apex_config = {
              xaxis = {
                type = "datetime";
                labels.datetimeFormatter = {
                  hour = "HH:mm";
                  day = "dd MMM";
                };
              };
              plotOptions.bar.colors.ranges = [
                {
                  from = 0;
                  to = 0.15;
                  color = "#2ecc71";
                }
                {
                  from = 0.15;
                  to = 0.2;
                  color = "#a6d96a";
                }
                {
                  from = 0.2;
                  to = 0.25;
                  color = "#ffff99";
                }
                {
                  from = 0.25;
                  to = 0.3;
                  color = "#fdae61";
                }
                {
                  from = 0.3;
                  to = 0.35;
                  color = "#f46d43";
                }
                {
                  from = 0.35;
                  to = 1;
                  color = "#d73027";
                }
              ];
            };
            series = [
              {
                entity = "sensor.ostrom_energy_spot_price";
                attribute = "prices";
                float_precision = 3;
                type = "column";
                name = "Preis";
                data_generator = ''
                  const prices = entity.attributes.prices;
                  return Object.entries(prices).map(([timestamp, value]) => {
                    const date = new Date(timestamp);
                    return [date, value];
                  });
                '';
                show = {
                  datalabels = false;
                  in_header = true;
                };
              }
            ];
            yaxis = [
              {
                min = 0;
                max = 0.5;
              }
            ];
          }
        ];
      }
    ];
  };
in
{
  config = lib.mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = lib.mkIf cfg.openFirewall (
      [ cfg.port ] ++ lib.optionals cfg.homekit.enable [ 21063 ]
    );
    # mDNS for zeroconf device discovery (Shelly, HomeKit, etc.)
    networking.firewall.allowedUDPPorts = lib.mkIf cfg.openFirewall [ 5353 ];

    services.home-assistant = {
      enable = true;
      configDir = cfg.configDir;
      customComponents =
        merossComponents
        ++ scenePresetsComponents
        ++ evccComponents
        ++ syrConnectComponents
        ++ scryptedComponents
        ++ homeConnectLocalComponents
        ++ homeConnectAltComponents
        ++ wasteCollectionScheduleComponents
        ++ ostromComponents;

      customLovelaceModules = lib.optionals cfg.ostrom.enable [
        pkgs.home-assistant-custom-lovelace-modules.apexcharts-card
      ];

      extraPackages = ps: [
        ps.psycopg2
      ];
      extraComponents = [
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
      ]
      ++ cfg.extraComponents
      ++ lib.optionals cfg.shelly.enable [ "shelly" ]
      ++ lib.optionals cfg.influxdb.enable [ "influxdb" ]
      ++ lib.optionals cfg.homekit.enable [ "homekit" ]
      ++ lib.optionals cfg.fronius.enable [ "fronius" ]
      ++ lib.optionals cfg.samsungTv.enable [ "samsungtv" ]
      ++ lib.optionals cfg.roborock.enable [ "roborock" ];

      # Note: MQTT broker connection must be configured via UI after onboarding
      # (Settings > Devices & Services > Add Integration > MQTT)
      # YAML config for broker settings is deprecated.
      config = lib.mkMerge [
        {
          lovelace = lib.mkMerge [
            { mode = "storage"; }
            (lib.mkIf cfg.ostrom.enable {
              dashboards.mares-home = {
                mode = "yaml";
                title = "Mares Home";
                icon = "mdi:home-lightning-bolt";
                filename = "${maresHomeDashboard}";
                show_in_sidebar = true;
              };
            })
          ];

          homeassistant = {
            name = "Home";
            time_zone = "Europe/Berlin";
            unit_system = "metric";
            temperature_unit = "C";
            latitude = "!secret latitude";
            longitude = "!secret longitude";
            country = "DE";
          };

          # Home zone with 50m radius for tighter geofencing
          zone = [
            {
              name = "Home";
              latitude = "!secret latitude";
              longitude = "!secret longitude";
              radius = 50;
              icon = "mdi:home";
            }
          ];

          # Enables zeroconf/mDNS discovery for Shelly and other devices
          default_config = { };

          http = {
            server_host = cfg.bindAddress;
            server_port = cfg.port;
            use_x_forwarded_for = cfg.trustedProxies != [ ];
            trusted_proxies = cfg.trustedProxies;
          };

          recorder = {
            db_url = "!secret recorder_db_url";
            purge_keep_days = cfg.recorder.purgeKeepDays;
            commit_interval = cfg.recorder.commitInterval;
            exclude = {
              domains = cfg.recorder.excludeDomains;
              entity_globs = [
                "sensor.*_last_restart"
              ];
            };
          };

          logger.default = "info";

          prometheus = { };
        }

        (lib.mkIf cfg.influxdb.enable {
          influxdb = {
            api_version = 2;
            ssl = false;
            host = cfg.influxdb.host;
            port = cfg.influxdb.port;
            organization = cfg.influxdb.organization;
            bucket = cfg.influxdb.bucket;
            token = "!secret influxdb_token";
            max_retries = cfg.influxdb.maxRetries;
            include.entity_globs = [ "sensor.*" ];
          };
        })

        (lib.mkIf cfg.homekit.enable {
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
  };
}
