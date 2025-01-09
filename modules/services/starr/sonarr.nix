{
  config,
  lib,
  cluster,
  ...
}:
let
  cfg = config.cluster.services.starr;
in
{
  config = lib.mkIf (cfg.enable && cfg.sonarr.enable) {
    sops.templates."sonarr-config.xml" = {
      content =
        cluster.lib.generators.toXML
          {
            rootName = "Config";
            xmlns = { };
          }
          {
            BindAddress = "${cfg.sonarr.bindAddress}";
            Port = 8989;
            SslPort = 9898;
            EnableSsl = false;
            LaunchBrowser = false;
            ApiKey = "${config.sops.placeholder.sonarr-api_key}";
            AuthenticationMethod = "Forms";
            AuthenticationRequired = "Enabled";
            Branch = "master";
            LogLevel = "debug";
            SslCertPath = "";
            SslCertPassword = "";
            UrlBase = "";
            InstanceName = "Sonarr";
            AnalyticsEnabled = false;
            PostgresUser = "sonarr";
            PostgresPassword = "${config.sops.placeholder.pgsql-sonarr_password}";
            PostgresPort = "${toString cfg.postgres.port}";
            PostgresHost = "${cfg.postgres.host}";
            PostgresMainDb = "sonarr";
            PostgresLogDb = "sonarr_log";
          };

      path = "${config.services.sonarr.dataDir}/config.xml";
      owner = cfg.sonarr.user;
      group = cfg.group;
      mode = "0660";

      restartUnits = [ "sonarr.service" ];
    };

    services.sonarr = {
      enable = true;
      dataDir = "${cfg.pathPrefix}/sonarr";
      group = cfg.group;
      openFirewall = true;
    };

    cluster.storage.truenas.media = {
      enable = cfg.sonarr.mountStorage;
    };

    systemd.services.sonarr = {
      wants = [
        "sops-nix.service"
        "mnt-media.mount"
      ];
      after = [
        "sops-nix.service"
        "mnt-media.mount"
      ];
    };
  };
}
