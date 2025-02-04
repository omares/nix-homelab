{
  pkgs,
  nodeCfg,
  ...
}:
{
  imports = [
    ../../services/scrypted.nix
    ../../users/scrypted.nix
  ];

  fileSystems."/scrypted-fast" = {
    device = "/dev/disk/by-label/scrypted-fast";
    autoResize = true;
    fsType = "ext4";
  };

  services.scrypted = {
    enable = true;
    package = pkgs.callPackage ../../packages/scrypted.nix { };
    openFirewall = true;
    extraEnvironment = {
      SCRYPTED_CLUSTER_MODE = "server";
      SCRYPTED_CLUSTER_ADDRESS = nodeCfg.host;
      SCRYPTED_CLUSTER_SECRET = "dummy";
      SCRYPTED_CLUSTER_LABELS = "storage";
    };
  };
}
