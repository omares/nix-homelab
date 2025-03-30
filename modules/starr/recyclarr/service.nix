{
  config,
  lib,
  ...
}:

let
  cfg = config.mares.starr;
in
{
  config = lib.mkIf (cfg.enable && cfg.recyclarr.enable) {
    services.recyclarr = {
      enable = true;
      user = cfg.recyclarr.user;
      group = cfg.group;
    };

    systemd.services.recyclarr = {
      serviceConfig = {
        LoadCredential = [
          "sonarr-api_key:${config.sops.secrets.sonarr-api_key.path}"
          "radarr-api_key:${config.sops.secrets.radarr-api_key.path}"
        ];
      };
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
