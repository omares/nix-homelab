{
  config,
  lib,
  ...
}:

let
  cfg = config.cluster.services.starr;
in
{
  config = lib.mkIf (cfg.enable && cfg.recyclarr.enable) {
    cluster.services.recyclarr = {
      enable = true;
      configFile = config.sops.templates."recyclarr.yaml".path;
      user = cfg.recyclarr.user;
      group = cfg.group;
    };

    systemd.services.recyclarr = {
      wants = [
        "sops-nix.service"
      ];
      after = [
        "sops-nix.service"
      ];
    };
  };
}
