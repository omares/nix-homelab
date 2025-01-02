{
  nodeCfg,
  ...
}:
{
  imports = [
    ../../services/starr
  ];

  cluster.services.starr = {
    enable = true;

    prowlarr = {
      enable = true;
      mountStorage = true;
      bindAddress = nodeCfg.host;
    };
  };
}
