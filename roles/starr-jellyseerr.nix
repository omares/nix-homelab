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

    jellyseerr = {
      enable = true;
      bindAddress = nodeCfg.host;
    };
  };
}
