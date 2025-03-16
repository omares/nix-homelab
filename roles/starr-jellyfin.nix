{
  pkgs,
  nodeCfg,
  ...
}:
{

  imports = [
    ../modules/starr
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

  mares.starr = {
    enable = true;

    jellyfin = {
      enable = true;
      mountStorage = true;
      bindAddress = nodeCfg.host;
    };
  };
}
