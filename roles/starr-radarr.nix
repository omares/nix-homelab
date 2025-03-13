{
  nodeCfg,
  ...
}:
{
  imports = [
    ../modules/services/starr
  ];

  mares.services.starr = {
    enable = true;

    radarr = {
      enable = true;
      mountStorage = true;
      bindAddress = nodeCfg.host;
    };
  };
}
