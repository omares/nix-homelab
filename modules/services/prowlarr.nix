{
  config,
  nodeCfg,
  ...
}:
{
  config = {
    sops.templates."config.xml" = {
      content = ''
        <Config>
          <BindAddress>${nodeCfg.host}</BindAddress>
          <Port>9696</Port>
          <SslPort>6969</SslPort>
          <EnableSsl>False</EnableSsl>
          <LaunchBrowser>True</LaunchBrowser>
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
        </Config>
      '';

      path = "/var/lib/prowlarr/config.xml";
      owner = "prowlarr";
      group = "prowlarr";

      restartUnits = [ "prowlarr.service" ];
    };

    services.prowlarr = {
      enable = true;
      openFirewall = true;
    };
  };
}
