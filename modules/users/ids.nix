{ lib, ... }:
{
  ids.gids = {
    sabnzbd = 3003;
    scrypted = 3004;
    starr = 3003;
  };

  ids.uids = {
    jellyfin = 383;
    jellyseerr = 384;
    omares = 3002;
    prowlarr = 381;
    recyclarr = 382;
    sabnzbd = lib.mkForce 380; # 38 is taken on TrueNAS
    scrypted = 385;
  };
}
