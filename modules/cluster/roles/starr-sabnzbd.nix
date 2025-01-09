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

    sabnzbd = {
      enable = true;
      mountStorage = true;
      bindAddress = nodeCfg.host;
    };
  };
}
