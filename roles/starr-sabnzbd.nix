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

    sabnzbd = {
      enable = true;
      mountStorage = true;
      bindAddress = nodeCfg.host;
    };
  };
}
