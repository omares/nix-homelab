{
  config,
  lib,
  nodeCfg,
  cluster,
  ...
}:
let
  owner = "prowlarr";
  group = "starr";
  dataDir = config.users.users.prowlarr.home;
in
{
  config = {
    sops.templates."prowlarr-config.xml" = {
      # lib.toXML creates weird XML that Prowlarr seems to have issues with.
      # I can't be bothered to convert this simple configuration to attributes.
      content = ''
        <Config>
          <BindAddress>${nodeCfg.host}</BindAddress>
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
          <PostgresPort>${toString config.services.pgbouncer.settings.pgbouncer.listen_port}</PostgresPort>
          <PostgresHost>${cluster.nodes.db-01.host}</PostgresHost>
          <PostgresMainDb>prowlarr</PostgresMainDb>
          <PostgresLogDb>prowlarr_log</PostgresLogDb>
        </Config>
      '';

      path = "${config.users.users.prowlarr.home}/config.xml";
      owner = owner;
      group = group;
      mode = "0660";

      restartUnits = [ "prowlarr.service" ];
    };

    services.prowlarr = {
      enable = true;
      openFirewall = true;
    };

    systemd.services.prowlarr = {
      serviceConfig = {
        DynamicUser = lib.mkForce false;
        User = lib.mkDefault owner;
        Group = lib.mkDefault group;
      };
    };
  };
}
