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

    prowlarr = {
      enable = true;
      mountStorage = true;
      bindAddress = nodeCfg.host;
    };
  };
}
