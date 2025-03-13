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

    recyclarr = {
      enable = true;
      bindAddress = nodeCfg.host;
    };
  };
}
