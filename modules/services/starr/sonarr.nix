{
  config,
  lib,
  ...
}:
let
  cfg = config.cluster.services.starr;
in
{
  config = lib.mkIf (cfg.enable && cfg.sonarr.enable) {
    sops.templates."sonarr-config.xml" = {
      # lib.toXML creates weird XML that radarr seems to have issues with.
      # I can't be bothered to convert this simple configuration to attributes.
      content = ''
        <Config>
          <BindAddress>${cfg.sonarr.bindAddress}</BindAddress>
          <Port>8989</Port>
          <SslPort>9898</SslPort>
          <EnableSsl>False</EnableSsl>
          <LaunchBrowser>False</LaunchBrowser>
          <ApiKey>${config.sops.placeholder.sonarr-api_key}</ApiKey>
          <AuthenticationMethod>Forms</AuthenticationMethod>
          <AuthenticationRequired>Enabled</AuthenticationRequired>
          <Branch>master</Branch>
          <LogLevel>debug</LogLevel>
          <SslCertPath></SslCertPath>
          <SslCertPassword></SslCertPassword>
          <UrlBase></UrlBase>
          <InstanceName>Sonarr</InstanceName>
          <AnalyticsEnabled>False</AnalyticsEnabled>
          <PostgresUser>sonarr</PostgresUser>
          <PostgresPassword>${config.sops.placeholder.pgsql-sonarr_password}</PostgresPassword>
          <PostgresPort>${toString cfg.postgres.port}</PostgresPort>
          <PostgresHost>${cfg.postgres.host}</PostgresHost>
          <PostgresMainDb>sonarr</PostgresMainDb>
          <PostgresLogDb>sonarr_log</PostgresLogDb>
        </Config>
      '';

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
