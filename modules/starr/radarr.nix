{
  config,
  lib,
  mares,
  ...
}:

let
  cfg = config.mares.starr;
in
{
  config = lib.mkIf (cfg.enable && cfg.radarr.enable) {
    sops.templates."radarr-config.xml" = {
      content =
        mares.infrastructure.lib.generators.toXML
          {
            rootName = "Config";
            xmlns = { };
          }
          {
            BindAddress = "${cfg.radarr.bindAddress}";
            Port = 7878;
            SslPort = 9898;
            EnableSsl = false;
            LaunchBrowser = false;
            ApiKey = "${config.sops.placeholder.radarr-api_key}";
            AuthenticationMethod = "Forms";
            AuthenticationRequired = "Enabled";
            Branch = "master";
            LogLevel = "debug";
            SslCertPath = "";
            SslCertPassword = "";
            UrlBase = "";
            InstanceName = "Radarr";
            AnalyticsEnabled = false;
            PostgresUser = "radarr";
            PostgresPassword = "${config.sops.placeholder.pgsql-radarr_password}";
            PostgresPort = "${toString cfg.postgres.port}";
            PostgresHost = "${cfg.postgres.host}";
            PostgresMainDb = "radarr";
            PostgresLogDb = "radarr_log";
          };

      path = "${config.services.radarr.dataDir}/config.xml";
      owner = cfg.radarr.user;
      group = cfg.group;
      mode = "0660";

      restartUnits = [ "radarr.service" ];
    };

    services.radarr = {
      enable = true;
      dataDir = "${cfg.pathPrefix}/radarr";
      group = cfg.group;
      openFirewall = true;
    };

    systemd.services.radarr = {
      wants = [
        "sops-nix.service"
      ];
      after = [
        "sops-nix.service"
      ];
    };
  };
}
