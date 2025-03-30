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

    systemd.services.sabnzbd = {
      wants = [
        "sops-nix.service"
      ];

      after = [
        "sops-nix.service"
      ];
    };
  };
}
