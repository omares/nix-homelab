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

    radarr = {
      enable = true;
      mountStorage = true;
      bindAddress = nodeCfg.host;
    };
  };
}
