{
  config,
  lib,
  ...
}:
let
  cfg = config.cluster.services.starr;
in
{
  config =
    lib.mkIf
      (
        cfg.enable
        && (
          cfg.prowlarr.enable
          || cfg.radarr.enable
          || cfg.sonarr.enable
          || cfg.recyclarr.enable
          || cfg.sabnzbd.enable
          || cfg.jellyfin.enable
          || cfg.jellyseerr.enable
        )
      )
      {
        sops-vault.items =
          [
            "starr"
          ]
          ++ lib.lists.optionals
            (cfg.prowlarr.enable || cfg.radarr.enable || cfg.sonarr.enable || cfg.jellyseerr.enable)
            [
              "pgsql"
            ];
      };
}
