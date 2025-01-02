{
  config,
  lib,
  ...
}:

let
  cfg = config.cluster.services.starr;
in
{
  config = lib.mkIf (cfg.enable && cfg.radarr.enable) {
    sops.templates."radarr-config.xml" = {
      # lib.toXML creates weird XML that radarr seems to have issues with.
      # I can't be bothered to convert this simple configuration to attributes.
      content = ''
        <Config>
          <BindAddress>${cfg.radarr.bindAddress}</BindAddress>
          <Port>7878</Port>
          <SslPort>9898</SslPort>
          <EnableSsl>False</EnableSsl>
          <LaunchBrowser>False</LaunchBrowser>
          <ApiKey>${config.sops.placeholder.radarr-api_key}</ApiKey>
          <AuthenticationMethod>Forms</AuthenticationMethod>
          <AuthenticationRequired>Enabled</AuthenticationRequired>
          <Branch>master</Branch>
          <LogLevel>debug</LogLevel>
          <SslCertPath></SslCertPath>
          <SslCertPassword></SslCertPassword>
          <UrlBase></UrlBase>
          <InstanceName>Radarr</InstanceName>
          <AnalyticsEnabled>False</AnalyticsEnabled>
          <PostgresUser>radarr</PostgresUser>
          <PostgresPassword>${config.sops.placeholder.pgsql-radarr_password}</PostgresPassword>
          <PostgresPort>${toString cfg.postgres.port}</PostgresPort>
          <PostgresHost>${cfg.postgres.host}</PostgresHost>
          <PostgresMainDb>radarr</PostgresMainDb>
          <PostgresLogDb>radarr_log</PostgresLogDb>
        </Config>
      '';

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

    cluster.storage.truenas.media = {
      enable = cfg.radarr.mountStorage;
    };

    systemd.services.radarr = {
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
