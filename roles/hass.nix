{
  config,
  nodeCfg,
  mares,
  ...
}:
let
  dbNode = mares.infrastructure.nodes.db-01;
  monNode = mares.infrastructure.nodes.mon-01;
  proxyNode = mares.infrastructure.nodes.proxy-01;
in
{
  imports = [
    ../modules/automation/home-assistant
    ../modules/backup/restic
  ];

  sops-vault.items = [
    "hass"
    "mqtt"
    "pgsql"
    "influxdb"
    "restic"
  ];

  sops.templates.hass-secrets = {
    content = ''
      # Home Assistant secrets - managed by sops-nix
      latitude: ${config.sops.placeholder."hass-latitude"}
      longitude: ${config.sops.placeholder."hass-longitude"}

      # Database connections
      recorder_db_url: "postgresql://hass:${config.sops.placeholder."pgsql-hass_password"}@${dbNode.dns.fqdn}:6432/hass"

      # MQTT
      mqtt_password: ${config.sops.placeholder."mqtt-hass_password"}

      # InfluxDB
      influxdb_token: ${config.sops.placeholder."influxdb-hass_token"}
    '';
    path = "/var/lib/hass/secrets.yaml";
    owner = "hass";
    group = "hass";
    mode = "0400";
  };

  mares.home-assistant = {
    enable = true;
    bindAddress = nodeCfg.host;
    trustedProxies = [ proxyNode.host ];

    influxdb = {
      enable = true;
      host = monNode.dns.fqdn;
    };

    mqtt.enable = true;
  };

  mares.backup.restic = {
    enable = true;
    sshKeyFile = config.sops.secrets.restic-ssh_private_key.path;

    jobs.hass = {
      repoPath = "hass";
      passwordFile = config.sops.secrets.restic-hass_repo_key.path;
      paths = [ "/var/lib/hass/.storage" ];
      timerConfig = {
        OnCalendar = "*-*-* 03:00:00";
      };
    };
  };

  systemd.services.home-assistant = {
    after = [ "sops-nix.service" ];
    wants = [ "sops-nix.service" ];
  };
}
