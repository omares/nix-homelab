{
  inputs,
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
    inputs.sops-nix.nixosModules.sops
    inputs.nix-sops-vault.nixosModules.sops-vault
    ../modules/storage/truenas.nix
    ../modules/services/postgres
  ];

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

  mares.storage.truenas.postgres-backup = {
    enable = true;
  };

  mares.db.postgres = {
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

  mares.db.postgres.backup =
    let
      mountPoint = config.mares.storage.truenas.postgres-backup.mountPoint;
    in
    {
      dbs-daily = {
        enable = true;
        databases = [
          "prowlarr"
          "radarr"
          "sonarr"
          "jellyseerr"
          "atuin"
        ];
        pgdumpOptions = "-Fc -b";
        compression = "zstd";
        compressionLevel = 10;
        location = "${mountPoint}";
        startAt = "*-*-* 02:15:00";
        keep = 7; # Keep last 7 backups
      };
      dbs-weekly = {
        enable = true;
        databases = [
          "prowlarr"
          "radarr"
          "sonarr"
          "jellyseerr"
          "atuin"
        ];
        pgdumpOptions = "-Fc -b";
        compression = "zstd";
        compressionLevel = 10;
        location = "${mountPoint}";
        startAt = "Mon *-*-* 04:00:00";
        keep = 4; # Keep last 4 backups
      };
      globals-weekly = {
        enable = true;
        backupAll = true;
        pgdumpOptions = "--globals-only";
        compression = "zstd";
        compressionLevel = 10;
        location = "${mountPoint}";
        startAt = "Tue *-*-* 04:00:00";
        keep = 4; # Keep last 4 backups
      };
    };

  sops-vault.items = [ "pgsql" ];

  environment.systemPackages = with pkgs; [
    pgcli
  ];

}
