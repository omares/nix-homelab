{
  config,
  nodeCfg,
  mares,
  ...
}:
let
  mqttNode = mares.infrastructure.nodes.mqtt-01;
in
{
  imports = [
    ../modules/automation/zigbee2mqtt
    ../modules/backup/restic
  ];

  sops-vault.items = [
    "zigbee2mqtt"
    "restic"
  ];

  mares.automation.zigbee2mqtt = {
    enable = true;
    serialPort = "/dev/serial/by-id/usb-Itead_Sonoff_Zigbee_3.0_USB_Dongle_Plus_V2_b4787b007712ef11bb8478b8bf9df066-if00-port0";

    mqtt = {
      server = "mqtts://${mqttNode.dns.fqdn}:8883";
      passwordFile = config.sops.secrets.zigbee2mqtt-mqtt_password.path;
    };

    networkKeyFile = config.sops.secrets.zigbee2mqtt-network_key.path;
    panIdFile = config.sops.secrets.zigbee2mqtt-pan_id.path;
    extPanIdFile = config.sops.secrets.zigbee2mqtt-ext_pan_id.path;
  };

  mares.backup.restic = {
    enable = true;
    sshKeyFile = config.sops.secrets.restic-ssh_private_key.path;

    jobs.zigbee2mqtt = {
      repoPath = "zigbee2mqtt";
      passwordFile = config.sops.secrets.restic-zigbee2mqtt_repo_key.path;
      paths = [ "/var/lib/zigbee2mqtt" ];
      timerConfig = {
        OnCalendar = "*-*-* 03:30:00";
      };
    };
  };

  systemd.services.zigbee2mqtt = {
    after = [ "sops-nix.service" ];
    wants = [ "sops-nix.service" ];
  };
}
