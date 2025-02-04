{
  pkgs,
  cluster,
  ...
}:
{
  imports = [
    ../../services/scrypted.nix
    ../../users/scrypted.nix
  ];

  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver # Primary driver for your UHD 630
      intel-media-sdk # QuickSync support for 9th gen
      intel-compute-runtime # OpenCL for hardware tonemapping
      intel-vaapi-driver # Backup driver, good to have
    ];
  };

  environment.systemPackages = with pkgs; [
    libva-utils # To test VA-API
    intel-gpu-tools # For GPU monitoring
  ];

  powerManagement = {
    cpuFreqGovernor = "schedutil";
    powertop.enable = true;
  };

  services.scrypted = {
    enable = true;
    package = pkgs.callPackage ../../packages/scrypted.nix { };
    openFirewall = true;
    extraEnvironment = {
      SCRYPTED_CLUSTER_MODE = "client";
      SCRYPTED_CLUSTER_ADDRESS = cluster.nodes.cam-01.host;
      SCRYPTED_CLUSTER_SECRET = "dummy";
      SCRYPTED_CLUSTER_LABELS = "compute,transcode,@scrypted/openvino";
    };
  };
}
