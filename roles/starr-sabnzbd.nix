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

    sabnzbd = {
      enable = true;
      mountStorage = true;
      bindAddress = nodeCfg.host;
    };
  };
}
