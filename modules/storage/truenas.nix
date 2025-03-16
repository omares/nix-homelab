{
  config,
  mares,
  lib,
  ...
}:

let
  mountOptions = [
    "vers=4"
    "rw"
    "noatime"
    "_netdev"
  ];
in
{
  options.mares.storage.truenas = {

    media = {
      enable = lib.mkEnableOption "Mount the 'media' TrueNAS storage.";

      mountPoint = lib.mkOption {
        type = lib.types.path;
        default = "/mnt/media";
        description = "Local mount point where the remote media storage will be mounted";
        example = "/mnt/media";
      };
    };

    postgres-backup = {
      enable = lib.mkEnableOption "Mount the PostgreSQL backup TrueNAS storage";

      mountPoint = lib.mkOption {
        type = lib.types.path;
        default = "/mnt/backup/postgres";
        description = "Local mount point where the remote backup storage will be mounted";
        example = "/mnt/backup/postgres";
      };
    };

    scrypted-large = {
      enable = lib.mkEnableOption "Mount the scrypted large storage";

      mountPoint = lib.mkOption {
        type = lib.types.path;
        default = "/mnt/scrypted-large";
        description = "Local mount point where the large storage will be mounted";
        example = "/mnt/scrypted-large";
      };
    };
  };

  config =
    let
      cfgMedia = config.mares.storage.truenas.media;
      cfgBackup = config.mares.storage.truenas.postgres-backup;
      cfgScrytedLarge = config.mares.storage.truenas.scrypted-large;
    in
    lib.mkMerge [
      (lib.mkIf cfgMedia.enable {
        fileSystems."${cfgMedia.mountPoint}" = {
          device = "${mares.infrastructure.nodes.truenas.host}:/mnt/storage01/Media";
          fsType = "nfs";
          options = mountOptions;
        };

        services.rpcbind.enable = lib.mkDefault true;
      })

      (lib.mkIf cfgBackup.enable {
        fileSystems."${cfgBackup.mountPoint}" = {
          device = "${mares.infrastructure.nodes.truenas.host}:/mnt/storage01/backups/postgres";
          fsType = "nfs";
          options = mountOptions;
        };

        services.rpcbind.enable = lib.mkDefault true;
      })

      (lib.mkIf cfgScrytedLarge.enable {
        fileSystems."${cfgScrytedLarge.mountPoint}" = {
          device = "${mares.infrastructure.nodes.truenas.host}:/mnt/storage01/scrypted";
          fsType = "nfs";
          options = mountOptions;
        };

        services.rpcbind.enable = lib.mkDefault true;
      })
    ];
}
