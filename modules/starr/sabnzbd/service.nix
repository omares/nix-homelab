{
  config,
  lib,
  ...
}:
let
  cfg = config.mares.starr;
in
{
  config = lib.mkIf (cfg.enable && cfg.sabnzbd.enable) {

    services.sabnzbd = {
      enable = true;
      group = cfg.group;
      openFirewall = true;
    };

    mares.storage.truenas.media = {
      enable = cfg.sabnzbd.mountStorage;
    };

    systemd.services.sabnzbd = {
      wants = [
        "sops-nix.service"
        "mnt-media.mount"
      ];
      after = [
        "sops-nix.service"
        "mnt-media.mount"
      ];
    };
  };
}
