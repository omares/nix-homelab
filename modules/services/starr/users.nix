{
  config,
  lib,
  ...
}:
let
  cfg = config.cluster.services.starr;
  enableArrs = cfg.prowlarr.enable || cfg.radarr.enable || cfg.sabnzbd.enable || cfg.sonarr.enable;
in
{
  config =

    lib.mkIf (cfg.enable && enableArrs) {

      ids.gids = {
        starr = 3003;
      };

      ids.uids = {
        sabnzbd = lib.mkForce 380; # 38 is taken on TrueNAS
        prowlarr = 381;
      };

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
