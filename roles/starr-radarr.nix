{
  nodeCfg,
  ...
}:
{
  imports = [
    ../modules/storage/truenas.nix
    ../modules/starr
  ];

  sops-vault.items = [
    "starr"
    "pgsql"
  ];

  mares.storage.truenas.media = {
    enable = true;
  };

  systemd.services.radarr = {
    wants = [
      "mnt-media.mount"
    ];

    after = [
      "mnt-media.mount"
    ];
  };

  mares.starr = {
    enable = true;

    radarr = {
      enable = true;
      mountStorage = true;
      bindAddress = nodeCfg.host;
    };
  };
}
