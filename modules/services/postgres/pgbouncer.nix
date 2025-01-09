{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.cluster.db.postgres;
in
{
  config = lib.mkIf cfg.enable {
    services.pgbouncer = {
      enable = true;
      package = pkgs.pgbouncer;
      openFirewall = true;

      settings = {
        pgbouncer = {
          listen_addr = "${cfg.listenAddress}";

          pool_mode = "transaction";
          max_client_conn = 300;
          max_db_connections = 100;
          max_user_connections = 100;

          auth_type = "scram-sha-256";
          auth_file = "${config.sops.templates."pgbouncer-userlist".path}";

          ignore_startup_parameters = "extra_float_digits";
          admin_users = cfg.adminUser;
          stats_users = cfg.adminUser;
        };

        databases = lib.mapAttrs (
          name: _: "host=${cfg.listenAddress} port=5432 dbname=${name}"
        ) cfg.databases;

        users = lib.mapAttrs (name: _: "pool_mode=transaction max_user_connections=50") cfg.users;
      };
    };

    sops.templates."pgbouncer-userlist" = {
      content = lib.concatLines (
        lib.mapAttrsToList (name: _: ''"${name}" "${config.sops.placeholder."pgsql-${name}_password"}"'') (
          { ${cfg.adminUser} = { }; } // cfg.users
        )
      );
      owner = config.services.pgbouncer.user;
      group = config.services.pgbouncer.group;
      restartUnits = [ "pgbouncer.service" ];
    };

    systemd.services.pgbouncer = {
      after = [
        "sops-nix.service"
        "postgresql.service"
      ];
      wants = [
        "sops-nix.service"
        "postgresql.service"
      ];
      # See https://github.com/NixOS/nixpkgs/pull/308700#issuecomment-2566048064
      serviceConfig = {
        Type = "notify-reload";
        ExecReload = "${pkgs.coreutils}/bin/kill -HUP $MAINPID";
      };
    };
  };
}
