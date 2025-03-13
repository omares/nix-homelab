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

    prowlarr = {
      enable = true;
      mountStorage = true;
      bindAddress = nodeCfg.host;
    };
  };
}
