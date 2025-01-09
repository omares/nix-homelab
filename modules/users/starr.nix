{ config, ... }:
let
  gid = 3003;
in
{

  config = {
    ids.gids = {
      sabnzbd = gid;
      starr = gid;
    };

    users.groups.starr = {
      gid = config.ids.gids.starr;
    };
  };

}
