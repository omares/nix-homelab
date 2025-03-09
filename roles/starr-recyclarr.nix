{
  nodeCfg,
  ...
}:
{
  imports = [
    ../modules/services/starr
  ];

  cluster.services.starr = {
    enable = true;

    recyclarr = {
      enable = true;
      bindAddress = nodeCfg.host;
    };
  };
}
