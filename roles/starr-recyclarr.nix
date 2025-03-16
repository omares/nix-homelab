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

    recyclarr = {
      enable = true;
      bindAddress = nodeCfg.host;
    };
  };
}
