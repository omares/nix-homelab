{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.mares.database.postgres;

  formatIp = ip: if lib.hasInfix "/" ip then ip else "${ip}/32";
in
{
  config = lib.mkIf cfg.enable {
    services.postgresql = {
      enable = true;
      package = pkgs.postgresql_16;
      dataDir = cfg.dataDir;
      enableTCPIP = true;

      identMap = ''
        db-01    root                postgres
        db-01    postgres            postgres
        db-01    ${cfg.adminUser}    ${cfg.adminUser}
      '';

      authentication = lib.mkForce (
        lib.concatLines (
          [
            # TYPE   DATABASE    USER                ADDRESS      METHOD
            # System users
            "local   all         root                peer"
            "local   all         postgres            peer"
            # Admin user
            "local   all         ${cfg.adminUser}    peer"
            "host    all         ${cfg.adminUser}    0.0.0.0/0    scram-sha-256"
          ]
          ++ lib.flatten (
            lib.mapAttrsToList (
              name: user:
              map (
                database: "host    ${database}    ${name}    ${formatIp cfg.listenAddress}    scram-sha-256"
              ) user.databases
            ) cfg.users
          )
        )
      );

      ensureDatabases = lib.attrNames cfg.databases;

      ensureUsers = [
        {
          name = cfg.adminUser;
          ensureClauses = {
            superuser = true;
            login = true;
            createdb = true;
            createrole = true;
          };
        }
      ]
      ++ (lib.mapAttrsToList (name: user: {
        inherit name;
        ensureDBOwnership = user.ensureDBOwnership;
        ensureClauses = {
          login = true;
          createdb = user.createdb;
        };
      }) cfg.users);

      settings = {
        listen_addresses = lib.mkDefault "${cfg.listenAddress}";
        max_connections = "100";

        # 16GB system
        shared_buffers = "4GB"; # 25% of RAM
        effective_cache_size = "12GB"; # 75% of RAM
        work_mem = "64MB"; # Per-operation memory
        maintenance_work_mem = "512MB"; # Memory for maintenance operations

        password_encryption = "scram-sha-256";
        ssl = false;

        timezone = "Europe/Berlin";
        client_encoding = "UTF8";

        # Logging
        log_connections = "on";
        log_disconnections = "on";
        log_min_duration_statement = "1000"; # Log queries taking more than 1s

        autovacuum = "on";
        autovacuum_max_workers = "3";
        autovacuum_naptime = "1min";
        autovacuum_vacuum_threshold = "50";
        autovacuum_vacuum_scale_factor = "0.2";

        max_wal_size = "2GB";
        min_wal_size = "80MB";

        checkpoint_timeout = "15min";
        checkpoint_completion_target = "0.9";

        max_parallel_workers_per_gather = "4";
        max_parallel_workers = "8";
        parallel_leader_participation = "on";
      };
    };
  };
}
