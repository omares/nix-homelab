{
  config,
  lib,
  ...
}:
let
  cfg = config.cluster.services.starr;
  enableArrs =
    cfg.prowlarr.enable
    || cfg.radarr.enable
    || cfg.sabnzbd.enable
    || cfg.sonarr.enable
    || cfg.recyclarr.enable;
in
{
  config =

    lib.mkIf (cfg.enable && enableArrs) {
      users.groups.starr = {
        gid = config.ids.gids.starr;
      };

      users.users = lib.mkIf cfg.prowlarr.enable {
        prowlarr = {
          home = "${cfg.pathPrefix}/prowlarr";
          uid = config.ids.uids.prowlarr;
          group = "starr";
        };
      };
    };
}
