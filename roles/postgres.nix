{
  config,
  nodeCfg,
  pkgs,
  ...
}:
let
  dataDir = "/mnt/postgres-data/${config.services.postgresql.package.psqlSchema}";
in
{
  imports = [
    ../modules/database/postgres
  ];

  sops-vault.items = [ "pgsql" ];

  fileSystems."/mnt/postgres-data" = {
    device = "/dev/disk/by-label/postgres";
    fsType = "ext4";
    options = [
      "defaults"
      "noatime"
    ];
  };

  systemd.tmpfiles.settings = {
    "postgresql-data" = {
      "${dataDir}" = {
        d = {
          user = "postgres";
          group = "postgres";
          mode = "0700";
        };
      };
    };
  };

  mares.database.postgres = {
    enable = true;
    listenAddress = nodeCfg.host;
    dataDir = "${dataDir}";
    databases = {
      prowlarr = { };
      prowlarr_log = { };
      radarr = { };
      radarr_log = { };
      sonarr = { };
      sonarr_log = { };
      jellyseerr = { };
      atuin = { };
    };
    users = {
      prowlarr = {
        ensureDBOwnership = true;
        createdb = false;
        databases = [
          "prowlarr"
          "prowlarr_log"
        ];
      };
      radarr = {
        ensureDBOwnership = true;
        createdb = false;
        databases = [
          "radarr"
          "radarr_log"
        ];
      };
      sonarr = {
        ensureDBOwnership = true;
        createdb = false;
        databases = [
          "sonarr"
          "sonarr_log"
        ];
      };
      jellyseerr = {
        ensureDBOwnership = true;
        createdb = false;
        databases = [
          "jellyseerr"
        ];
      };
      atuin = {
        ensureDBOwnership = true;
        createdb = false;
        databases = [
          "atuin"
        ];
        pgbouncerParams = {
          pool_mode = "session";
        };
      };
    };
  };

  environment.systemPackages = with pkgs; [
    pgcli
  ];
}
