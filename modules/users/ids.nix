{ lib, ... }:
{
  ids.gids = {
    starr = 3003;
  };

  ids.uids = {
    sabnzbd = lib.mkForce 380; # 38 is taken on TrueNAS
    prowlarr = 381;
    recyclarr = 382;
    jellyfin = 383;
  };
}
