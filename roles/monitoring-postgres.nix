{
  config,
  lib,
  ...
}:
let
  pgbouncerPort = config.services.pgbouncer.settings.pgbouncer.listen_port or 6432;
in
{
  imports = [
    ../modules/monitoring
  ];

  mares.monitoring.roles = [ "monitoring-postgres" ];

  # postgres exporter - runs as local postgres superuser for full metrics access
  services.prometheus.exporters.postgres = {
    enable = true;
    runAsLocalSuperUser = true;
  };

  # pgbouncer exporter - monitors connection pooling metrics
  services.prometheus.exporters.pgbouncer = {
    enable = true;
    connectionEnvFile = config.sops.templates."pgbouncer-exporter-env".path;
  };

  # sops template for pgbouncer exporter connection string
  sops.templates."pgbouncer-exporter-env" = {
    content = ''
      PGBOUNCER_EXPORTER_CONNECTION_STRING=postgres://${config.mares.database.postgres.adminUser}:${
        config.sops.placeholder."pgsql-${config.mares.database.postgres.adminUser}_password"
      }@${config.mares.database.postgres.listenAddress}:${toString pgbouncerPort}/pgbouncer?sslmode=disable
    '';
    restartUnits = [ "prometheus-pgbouncer-exporter.service" ];
  };

  # Alloy scrapes these exporters locally and pushes to Prometheus
  mares.monitoring.alloy.extraScrapeTargets = [
    {
      job = "postgres";
      targets = [ "localhost:9187" ];
    }
    {
      job = "pgbouncer";
      targets = [ "localhost:9127" ];
    }
  ];
}
