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

    jellyseerr = {
      enable = true;
      bindAddress = nodeCfg.host;
    };
  };
}
