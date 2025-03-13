{
  nodeCfg,
  ...
}:
{
  imports = [
    ../modules/services/starr
  ];

  # https://github.com/NixOS/nixpkgs/issues/360592
  # https://github.com/Sonarr/Sonarr/pull/7443
  nixpkgs.config.permittedInsecurePackages = [
    "aspnetcore-runtime-6.0.36"
    "aspnetcore-runtime-wrapped-6.0.36"
    "dotnet-sdk-6.0.428"
    "dotnet-sdk-wrapped-6.0.428"
  ];

  mares.services.starr = {
    enable = true;

    sonarr = {
      enable = true;
      mountStorage = true;
      bindAddress = nodeCfg.host;
    };
  };
}
