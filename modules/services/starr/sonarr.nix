{
  config,
  nodeCfg,
  cluster,
  ...
}:
let
  owner = "sonarr";
  group = "starr";
in
{
  config = {
    sops.templates."sonarr-config.xml" = {
      # lib.toXML creates weird XML that radarr seems to have issues with.
      # I can't be bothered to convert this simple configuration to attributes.
      content = ''
        <Config>
          <BindAddress>${nodeCfg.host}</BindAddress>
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
          <PostgresPort>${toString config.services.pgbouncer.settings.pgbouncer.listen_port}</PostgresPort>
          <PostgresHost>${cluster.nodes.db-01.host}</PostgresHost>
          <PostgresMainDb>sonarr</PostgresMainDb>
          <PostgresLogDb>sonarr_log</PostgresLogDb>
        </Config>
      '';

      path = "${config.services.sonarr.dataDir}/config.xml";
      owner = owner;
      group = group;
      mode = "0660";

      restartUnits = [ "sonarr.service" ];
    };

    services.sonarr = {
      enable = true;
      dataDir = "/var/lib/sonarr";
      group = group;
      openFirewall = true;
    };
  };
}
