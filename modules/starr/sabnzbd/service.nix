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

      # Memory grows over weeks until the OOM killer stops it; come back up instead of staying down
      serviceConfig = {
        Restart = "on-failure";
        RestartSec = "30s";
      };
    };
  };
}
