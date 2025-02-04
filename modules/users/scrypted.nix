{ config, ... }:
{

  config = {
    users.groups.scrypted = {
      gid = config.ids.gids.scrypted;
    };

    users.users = {
      scrypted = {
        uid = config.ids.uids.scrypted;
        group = "starr";
      };
    };
  };

}
