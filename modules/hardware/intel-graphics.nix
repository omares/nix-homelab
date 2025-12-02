{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.mares.hardware.intel-graphics;
in
{
  options.mares.hardware.intel-graphics = {
    enable = lib.mkEnableOption "Enable Intel graphics driver";
  };

  config = lib.mkIf cfg.enable {

    hardware.graphics = {
      enable = true;
      extraPackages = with pkgs; [
        intel-media-driver # Primary driver for UHD 630
        #intel-compute-runtime
        intel-compute-runtime-legacy1 # OpenCL for hardware tonemapping
        # intel-vaapi-driver # Backup driver, good to have
        # libva-vdpau-driver
        ocl-icd
      ];
    };

    environment.systemPackages = with pkgs; [
      libva-utils # To test VA-API
      intel-gpu-tools # For GPU monitoring
      clinfo
    ];

    powerManagement = {
      cpuFreqGovernor = "schedutil";
      powertop.enable = true;
    };
  };
}
