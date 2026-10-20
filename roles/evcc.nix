{
  config,
  mares,
  inputs,
  pkgs,
  ...
}:
let
  mqttNode = mares.infrastructure.nodes.mqtt-01;
in
{
  imports = [ ../modules/automation/evcc ];

  services.evcc.package = inputs.nixpkgs-master.legacyPackages.${pkgs.system}.evcc;

  sops-vault.items = [ "evcc" ];

  # Generate the environment file for envsubst
  # Vault item: evcc
  # Expected keys: mqtt_password, bmw_client_d, bmw_vin, ostrom_client_id, ostrom_client_secret, sponsor_token
  sops.templates."evcc-env".content = ''
    MQTT_PASSWORD=${config.sops.placeholder.evcc-mqtt_password}
    BMW_CLIENTID=${config.sops.placeholder.evcc-bmw_clientid}
    BMW_VIN=${config.sops.placeholder.evcc-bmw_vin}
    OSTROM_ID=${config.sops.placeholder.evcc-ostrom_client_id}
    OSTROM_SECRET=${config.sops.placeholder.evcc-ostrom_client_secret}
    SPONSOR_TOKEN=${config.sops.placeholder.evcc-sponsor_token}
  '';

  mares.automation.evcc = {
    enable = true;
    secretsFile = config.sops.templates."evcc-env".path;

    settings = {

      interval = "30s";
      sponsortoken = "${"\${SPONSOR_TOKEN}"}";

      mqtt = {
        broker = "tls://${mqttNode.dns.fqdn}:8883";
        topic = "evcc";
        user = "evcc";
        password = "\${MQTT_PASSWORD}";
      };

      meters = [
        {
          name = "fronius_smart_meter";
          type = "template";
          template = "sunspec-meter";
          usage = "grid";
          modbus = "tcpip";
          id = 240;
          host = "192.168.20.24";
          port = 502;
        }
        {
          name = "fronius_symo_inverter";
          type = "template";
          template = "sunspec-inverter";
          usage = "pv";
          modbus = "tcpip";
          id = 1;
          host = "192.168.20.24";
          port = 502;
        }
        {
          name = "varta_pulse_neo";
          type = "template";
          template = "varta";
          usage = "battery";
          # Pulse Neo 6 datasheet: 6.5 kWh at 90 % DoD, 2.5 / 2.3 kW AC charge / discharge
          capacity = 6.5;
          maxdischargepower = 2300;
          host = "192.168.20.129";
        }
      ];

      chargers = [
        {
          name = "fronius_wattpilot";
          type = "template";
          template = "ocpp-goe";
          stationid = "91008988";
        }
        {
          name = "stiebel_eltron_lwz_5s_trend";
          type = "template";
          template = "stiebel-lwa";
          modbus = "tcpip";
          host = "192.168.20.111";
          tempsource = "warmwater";
        }
      ];

      loadpoints = [
        {
          title = "Carport";
          charger = "fronius_wattpilot";
          vehicle = "bmw_ix40";
          mode = "smart";
        }
        {
          title = "LWZ 5s Trend";
          charger = "stiebel_eltron_lwz_5s_trend";
          mode = "smart";
          # Gets surplus before the car (Carport has the default priority 0)
          priority = 1;
          # Compressor only (no backup heater, SG-Ready WW setpoint 50 °C): ~1.0-1.5 kW typical,
          # ~2.1 kW max, single-phase 230 V
          phases = 1;
          mincurrent = 5;
          maxcurrent = 9;
          enable = {
            threshold = -1300;
            delay = "5m";
          };
          disable = {
            threshold = 200;
            delay = "20m";
          };
        }
      ];

      vehicles = [
        {
          name = "bmw_ix40";
          type = "template";
          title = "BMW iX40";
          template = "cardata";
          clientid = "\${BMW_CLIENTID}";
          vin = "\${BMW_VIN}";
          # usable capacity (76.6 kWh gross)
          capacity = 71;
          streaming = true;
        }
      ];

      tariffs = {
        grid = {
          type = "template";
          template = "ostrom";
          clientid = "\${OSTROM_ID}";
          clientsecret = "\${OSTROM_SECRET}";
        };
        feedin = {
          type = "fixed";
          price = 0.0877;
        };
        solar = [
          {
            type = "template";
            template = "open-meteo";
            lat = 52.396;
            lon = 13.293;
            # 24 x 310 Wp on the south-east roof (131 deg compass, 0 = south)
            kwp = 7.44;
            dec = 22;
            az = -49;
            # Fronius Symo 7.0-3-M: measured output caps at ~6.74 kW (no feed-in limit set)
            ac = 6.75;
          }
        ];
      };

      site = {
        title = "Mares Home";
        # Keep ~100 W export as buffer while following PV surplus
        residualPower = 100;
        meters = {
          grid = "fronius_smart_meter";
          pv = [ "fronius_symo_inverter" ];
          battery = [ "varta_pulse_neo" ];
        };
      };
    };
  };
}
