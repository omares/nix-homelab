{
  nodeCfg,
  ...
}:
{
  imports = [
    ../modules/starr
  ];

  mares.starr = {
    enable = true;

    radarr = {
      enable = true;
      mountStorage = true;
      bindAddress = nodeCfg.host;
    };
  };
}
