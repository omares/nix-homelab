{
  pkgs,
  lib,
  name,
  cluster,
  ...
}:
{
  imports = [
    ../../automation/scrypted.nix
  ];

  cluster.automation.scrypted = {
    enable = true;
    role = "client-openvino";
    serverHost = cluster.nodes.cam-01.host;
    workerName = name;
  };

  # hardware.graphics = {
  #   enable = true;
  #   extraPackages = with pkgs; [
  #     intel-media-driver # Primary driver for UHD 630
  #     intel-media-sdk # QuickSync support for 9th gen
  #     intel-compute-runtime # OpenCL for hardware tonemapping
  #     intel-vaapi-driver # Backup driver, good to have
  #   ];
  # };

  # environment.systemPackages = with pkgs; [
  #   libva-utils # To test VA-API
  #   intel-gpu-tools # For GPU monitoring
  # ];

  # powerManagement = {
  #   cpuFreqGovernor = "schedutil";
  #   powertop.enable = true;
  # };

  # services.scrypted = {
  #   enable = true;
  #   package = pkgs.callPackage ../../packages/scrypted.nix { };
  #   openFirewall = true;
  #   extraEnvironment = {
  #     SCRYPTED_CLUSTER_MODE = "client";
  #     SCRYPTED_CLUSTER_WORKER_NAME = name;
  #     SCRYPTED_CLUSTER_SERVER = cluster.nodes.cam-01.host;
  #     SCRYPTED_CLUSTER_SECRET = "dummy";
  #     SCRYPTED_CLUSTER_LABELS = "compute,transcode,@scrypted/openvino";
  #   };
  # };

  # users.users.scrypted = {
  #   extraGroups = [
  #     "video"
  #     "render"
  #   ];
  # };

  # systemd.services.scrypted = {
  #   serviceConfig = {
  #     # Device access
  #     DeviceAllow = [
  #       "/dev/dri/renderD128" # GPU render node for encoding/decoding
  #       "/dev/dri/card1" # Main GPU device for display/acceleration
  #     ];
  #   };
  # };

  # # networking.firewall.enable = lib.mkForce false;

  # networking.firewall = {
  #   allowedTCPPortRanges = [
  #     {
  #       from = 32768;
  #       to = 60999;
  #     }
  #   ];
  # };
}
