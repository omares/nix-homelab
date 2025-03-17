{
  nodeCfg,
  ...
}:
{

  imports = [
    ../modules/storage/truenas.nix
    ../modules/starr
  ];

  sops-vault.items = [ "starr" ];

  mares.storage.truenas.media = {
    enable = true;
  };

  systemd.services.sabnzbd = {
    wants = [
      "mnt-media.mount"
    ];

    after = [
      "mnt-media.mount"
    ];
  };

  mares.starr = {
    enable = true;

    sabnzbd = {
      enable = true;
      mountStorage = true;
      bindAddress = nodeCfg.host;
    };
  };
}
