{
  inputs,
  config,
  cluster,
  nodeCfg,
  pkgs,
  lib,
  ...
}:
{
  imports = [
    inputs.sops-nix.nixosModules.sops
    inputs.nix-sops-vault.nixosModules.sops-vault
    ../../storage/truenas.nix
    ../../services/postgres
  ];

  cluster.storage.truenas.postgres-backup = {
    enable = true;
  };

  cluster.db.postgres = {
    enable = true;
    listenAddress = nodeCfg.host;
    databases = {
      prowlarr = { };
      prowlarr_log = { };
      radarr = { };
      radarr_log = { };
      sonarr = { };
      sonarr_log = { };
      jellyseerr = { };
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
    };
  };

  cluster.db.postgres.backup =
    let
      mountPoint = config.cluster.storage.truenas.postgres-backup.mountPoint;
    in
    {
      dbs-daily = {
        enable = true;
        databases = [
          "prowlarr"
          "radarr"
          "sonarr"
          "jellyseerr"
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
