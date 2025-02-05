{
  nodeCfg,
  ...
}:
{
  imports = [
    ../../automation/scrypted.nix
  ];

  cluster.automation.scrypted = {
    enable = true;
    role = "server";
    serverHost = nodeCfg.host;
  };

  # fileSystems."/scrypted-fast" = {
  #   device = "/dev/disk/by-label/scrypted-fast";
  #   autoResize = true;
  #   fsType = "ext4";
  # };

  # services.scrypted = {
  #   enable = true;
  #   package = pkgs.callPackage ../../packages/scrypted.nix { };
  #   openFirewall = true;
  #   extraEnvironment = {
  #     SCRYPTED_ADMIN_ADDRESS = nodeCfg.host;
  #     SCRYPTED_CLUSTER_MODE = "server";
  #     SCRYPTED_CLUSTER_ADDRESS = nodeCfg.host;
  #     SCRYPTED_CLUSTER_SECRET = "dummy";
  #     SCRYPTED_CLUSTER_LABELS = "storage,";
  #   };
  # };

  # # networking.firewall.enable = lib.mkForce false;

  # # Used for communication between cluster servers and clients.
  # networking.firewall = {
  #   allowedTCPPorts = [
  #     10556
  #   ];

  #   allowedTCPPortRanges = [
  #     {
  #       from = 32768;
  #       to = 60999;
  #     }
  #   ];
  # };

}
