{
  config,
  cluster,
  lib,
  ...
}:

let
  cfg = config.homelab.storage.truenas.media;
in
{
  options.homelab.storage.truenas.media = {
    enable = lib.mkEnableOption "Mount the 'media' TrueNAS storage.";

    uid = lib.mkOption {
      type = lib.types.nullOr lib.types.int;
      default = null;
      description = "UID that should own the NFS mount. If null, no specific user ownership is set.";
      example = 1000;
    };
  };

  config = lib.mkIf cfg.enable {

    fileSystems."/mnt/media" = {
      device = "${cluster.nodes.truenas.host}:/mnt/storage01/Media";
      fsType = "nfs";
      options = [
        "vers=4" # Use NFS version 4 protocol
        "rw" # Mount as read-write
        "noatime" # Don't update access times (better performance)
        "_netdev" # Indicates this is a network mount
      ];
    };

    services.rpcbind.enable = lib.mkDefault true;
  };
}
