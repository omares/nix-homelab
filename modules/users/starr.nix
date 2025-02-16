{ config, ... }:
{

  config = {
    users.groups.starr = {
      gid = config.ids.gids.starr;
    };
  };

}
