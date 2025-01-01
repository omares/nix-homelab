{
  config,
  nodeCfg,
  cluster,
  ...
}:
let
  owner = "radarr";
  group = "starr";
in
{
  config = {
    sops.templates."radarr-config.xml" = {
      # lib.toXML creates weird XML that radarr seems to have issues with.
      # I can't be bothered to convert this simple configuration to attributes.
      content = ''
        <Config>
          <BindAddress>${nodeCfg.host}</BindAddress>
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
          <PostgresPort>${toString config.services.pgbouncer.settings.pgbouncer.listen_port}</PostgresPort>
          <PostgresHost>${cluster.nodes.db-01.host}</PostgresHost>
          <PostgresMainDb>radarr</PostgresMainDb>
          <PostgresLogDb>radarr_log</PostgresLogDb>
        </Config>
      '';

      path = "${config.services.radarr.dataDir}/config.xml";
      owner = owner;
      group = group;
      mode = "0660";

      restartUnits = [ "radarr.service" ];
    };

    services.radarr = {
      enable = true;
      dataDir = "/var/lib/radarr";
      group = group;
      openFirewall = true;
    };
  };
}
