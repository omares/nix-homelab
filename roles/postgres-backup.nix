{
  config,
  ...
}:
let
  mountPoint = config.mares.storage.truenas.postgres-backup.mountPoint;
in
{
  imports = [
    ../modules/storage/truenas.nix
    ../modules/services/postgresql-backup.nix
  ];

  mares.storage.truenas.postgres-backup = {
    enable = true;
  };

  mares.services.postgresql-backup = {
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

}
