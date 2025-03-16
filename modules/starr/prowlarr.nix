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
  config = lib.mkIf (cfg.enable && cfg.prowlarr.enable) {
    sops.templates."prowlarr-config.xml" = {
      content =
        mares.lib.generators.toXML
          {
            rootName = "Config";
            xmlns = { };
          }
          {
            BindAddress = "${cfg.prowlarr.bindAddress}";
            Port = 9696;
            SslPort = 6969;
            EnableSsl = false;
            LaunchBrowser = false;
            ApiKey = config.sops.placeholder.prowlarr-api_key;
            AuthenticationMethod = "Forms";
            AuthenticationRequired = "Enabled";
            Branch = "master";
            LogLevel = "debug";
            SslCertPath = "";
            SslCertPassword = "";
            UrlBase = "";
            InstanceName = "Prowlarr";
            AnalyticsEnabled = false;
            PostgresUser = "prowlarr";
            PostgresPassword = config.sops.placeholder.pgsql-prowlarr_password;
            PostgresPort = "${toString cfg.postgres.port}";
            PostgresHost = "${cfg.postgres.host}";
            PostgresMainDb = "prowlarr";
            PostgresLogDb = "prowlarr_log";
          };

      path = "${config.users.users.prowlarr.home}/config.xml";
      owner = cfg.prowlarr.user;
      group = cfg.group;
      mode = "0660";

      restartUnits = [ "prowlarr.service" ];
    };

    services.prowlarr = {
      enable = true;
      openFirewall = true;
    };

    mares.storage.truenas.media = {
      enable = cfg.prowlarr.mountStorage;
    };

    systemd.services.prowlarr = {
      serviceConfig = {
        DynamicUser = lib.mkForce false;
        User = lib.mkDefault cfg.prowlarr.user;
        Group = lib.mkDefault cfg.group;
      };

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
