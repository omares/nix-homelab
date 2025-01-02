{
  config,
  lib,
  ...
}:
let
  cfg = config.cluster.services.starr;
  enableArrs = cfg.prowlarr.enable || cfg.radarr.enable || cfg.sonarr.enable;
in
{
  config = lib.mkIf (cfg.enable && (enableArrs || cfg.sabnzbd.enable)) {
    sops-vault.items =
      [
        "starr"
      ]
      ++ lib.lists.optionals enableArrs [
        "pgsql"
      ];
  };
}
