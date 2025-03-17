{
  nodeCfg,
  ...
}:
{
  imports = [
    ../modules/starr
  ];

  sops-vault.items = [
    "starr"
    "pgsql"
  ];

  mares.storage.truenas.media = {
    enable = true;
  };

  systemd.services.sonarr = {
    wants = [
      "mnt-media.mount"
    ];

    after = [
      "mnt-media.mount"
    ];
  };

  # https://github.com/NixOS/nixpkgs/issues/360592
  # https://github.com/Sonarr/Sonarr/pull/7443
  nixpkgs.config.permittedInsecurePackages = [
    "aspnetcore-runtime-6.0.36"
    "aspnetcore-runtime-wrapped-6.0.36"
    "dotnet-sdk-6.0.428"
    "dotnet-sdk-wrapped-6.0.428"
  ];

  mares.starr = {
    enable = true;

    sonarr = {
      enable = true;
      mountStorage = true;
      bindAddress = nodeCfg.host;
    };
  };
}
