{
  config,
  lib,
  nodeCfg,
  ...
}:
{
  imports = [
    ../modules/storage/truenas.nix
    ../modules/automation/scrypted
  ];

  sops-vault.items = [ "scrypted" ];

  fileSystems."/mnt/scrypted-fast" = {
    device = "/dev/disk/by-label/scrypted-fast";
    autoResize = true;
    fsType = "ext4";
  };

  mares.storage.truenas.scrypted-large = {
    enable = true;
  };

  systemd.services.scrypted = {
    wants = [
      "mnt-scrypted-large.mount"
    ];

    after = [
      "mnt-scrypted-large.mount"
    ];

    serviceConfig.ReadWritePaths = lib.mkAfter [
      "/mnt/scrypted-fast/data"
      config.mares.storage.truenas.scrypted-large.mountPoint
    ];
  };

  mares.automation.scrypted = {
    enable = true;
    role = "server";
    serverHost = nodeCfg.host;

    plugins = [
      "amcrest"
      "diagnostics"
      "dummy-switch"
      "doorbird"
      "onvif"
      "openvino"
      "prebuffer-mixin"
      "rtsp"
      "cloud"
      "core"
      "nvr"
      "snapshot"
      "objectdetector"
      "webrtc"
    ];
  };
}
