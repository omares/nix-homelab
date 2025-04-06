{
  nodeCfg,
  ...
}:
{

  imports = [
    ../modules/storage/truenas.nix
    ../modules/hardware/intel-graphics.nix
    ../modules/starr
  ];

  sops-vault.items = [ "starr" ];

  mares.storage.truenas.media = {
    enable = true;
  };

  systemd.services.jellyfin = {
    wants = [
      "mnt-media.mount"
    ];
    after = [
      "mnt-media.mount"
    ];
  };

  mares.hardware.intel-graphics = {
    enable = true;
  };

  mares.starr = {
    enable = true;

    jellyfin = {
      enable = true;
      bindAddress = nodeCfg.host;
    };
  };
}
