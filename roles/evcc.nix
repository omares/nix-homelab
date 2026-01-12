{
  config,
  mares,
  ...
}:
let
  mqttNode = mares.infrastructure.nodes.mqtt-01;
in
{
  imports = [ ../modules/automation/evcc ];

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
      ];

      loadpoints = [
        {
          title = "Carport";
          charger = "fronius_wattpilot";
          vehicle = "bmw_ix40";
          mode = "pv";
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
          capacity = 76.6;
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
      };

      site = {
        title = "Mares Home";
        meters = {
          grid = "fronius_smart_meter";
          pv = [ "fronius_symo_inverter" ];
          battery = [ "varta_pulse_neo" ];
        };
      };
    };
  };
}
