{
  lib,
  config,
  ...
}:
let
  cfg = config.mares.monitoring.loki;
in
{
  options.mares.monitoring.loki = {
    enable = lib.mkEnableOption "Enable Loki";

    port = lib.mkOption {
      type = lib.types.port;
      default = 3100;
      description = "Port for Loki";
    };

    retentionPeriod = lib.mkOption {
      type = lib.types.str;
      default = "336h";
      description = "Log retention period";
    };
  };

  config = lib.mkIf cfg.enable {
    services.loki = {
      enable = true;

      configuration = {
        server = {
          http_listen_address = "0.0.0.0";
          http_listen_port = cfg.port;
          grpc_listen_port = 9096;
        };

        auth_enabled = false;

        ingester = {
          lifecycler = {
            address = "127.0.0.1";
            ring = {
              kvstore = {
                store = "inmemory";
              };
              replication_factor = 1;
            };
          };
          chunk_idle_period = "1h";
          max_chunk_age = "1h";
          chunk_target_size = 1048576;
          chunk_retain_period = "30s";
        };

        schema_config = {
          configs = [
            {
              from = "2024-01-01";
              store = "tsdb";
              object_store = "filesystem";
              schema = "v13";
              index = {
                prefix = "index_";
                period = "24h";
              };
            }
          ];
        };

        storage_config = {
          tsdb_shipper = {
            active_index_directory = "/var/lib/loki/tsdb-shipper-active";
            cache_location = "/var/lib/loki/tsdb-shipper-cache";
            cache_ttl = "24h";
          };

          filesystem = {
            directory = "/var/lib/loki/chunks";
          };
        };

        limits_config = {
          reject_old_samples = true;
          reject_old_samples_max_age = "168h";
          retention_period = cfg.retentionPeriod;
        };

        compactor = {
          working_directory = "/var/lib/loki/compactor";
          compaction_interval = "10m";
          retention_enabled = true;
          retention_delete_delay = "2h";
          retention_delete_worker_count = 150;
          delete_request_store = "filesystem";
        };
      };
    };

    networking.firewall = {
      allowedTCPPorts = [ cfg.port ];
    };
  };
}
