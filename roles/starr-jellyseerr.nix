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

    jellyseerr = {
      enable = true;
      bindAddress = nodeCfg.host;
    };
  };
}
