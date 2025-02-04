{ config, ... }:
{

  config = {
    users.users = {
      prowlarr = {
        home = "/var/lib/prowlarr";
        uid = config.ids.uids.prowlarr;
        group = "starr";
      };
    };
  };

}
