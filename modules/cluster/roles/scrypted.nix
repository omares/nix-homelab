{ pkgs, ... }:
{
  imports = [
    ../../services/scrypted.nix
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
    # installPath = "/custom/path";  # Optional, defaults to /var/lib/scrypted
  };
}
