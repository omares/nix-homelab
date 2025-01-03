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

    recyclarr = {
      enable = true;
      bindAddress = nodeCfg.host;
    };
  };
}
