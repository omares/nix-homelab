{
  config,
  lib,
  ...
}:
let
  cfg = config.cluster.services.starr;
in
{
  config = lib.mkIf (cfg.enable && cfg.prowlarr.enable) {
    sops.templates."prowlarr-config.xml" = {
      # lib.toXML creates weird XML that Prowlarr seems to have issues with.
      # I can't be bothered to convert this simple configuration to attributes.
      content = ''
        <Config>
          <BindAddress>${cfg.prowlarr.bindAddress}</BindAddress>
          <Port>9696</Port>
          <SslPort>6969</SslPort>
          <EnableSsl>False</EnableSsl>
          <LaunchBrowser>False</LaunchBrowser>
          <ApiKey>${config.sops.placeholder.prowlarr-api_key}</ApiKey>
          <AuthenticationMethod>Forms</AuthenticationMethod>
          <AuthenticationRequired>Enabled</AuthenticationRequired>
          <Branch>master</Branch>
          <LogLevel>debug</LogLevel>
          <SslCertPath></SslCertPath>
          <SslCertPassword></SslCertPassword>
          <UrlBase></UrlBase>
          <InstanceName>Prowlarr</InstanceName>
          <AnalyticsEnabled>False</AnalyticsEnabled>
          <PostgresUser>prowlarr</PostgresUser>
          <PostgresPassword>${config.sops.placeholder.pgsql-prowlarr_password}</PostgresPassword>
          <PostgresPort>${toString cfg.postgres.port}</PostgresPort>
          <PostgresHost>${cfg.postgres.host}</PostgresHost>
          <PostgresMainDb>prowlarr</PostgresMainDb>
          <PostgresLogDb>prowlarr_log</PostgresLogDb>
        </Config>
      '';

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

    cluster.storage.truenas.media = {
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
