{
  lib,
  config,
  ...
}:
let
  cfg = config.mares.monitoring.prometheus;
in
{
  options.mares.monitoring.prometheus = {
    enable = lib.mkEnableOption "Enable prometheus";
  };

  config = lib.mkIf cfg.enable {

    services.prometheus = {
      retentionTime = "30d";

      globalConfig = {
        scrape_interval = "15s";
        evaluation_interval = "15s";
        scrape_timeout = "10s";
      };

      scrapeConfigs = [
        {
          job_name = "prometheus";
          static_configs = [
            { targets = [ "localhost:9090" ]; }
          ];
        }
      ];
    };

    networking.firewall = {
      enable = true;
      allowedTCPPorts = [
        9090
        9100
      ];
    };
  };
}
