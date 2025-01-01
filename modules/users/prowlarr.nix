{ config, ... }:
{

  config = {
    ids.uids = {
      prowlarr = 381;
    };

    users.users = {
      prowlarr = {
        home = "/var/lib/prowlarr";
        uid = config.ids.uids.prowlarr;
        group = "starr";
      };
    };
  };

}
