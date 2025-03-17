{
  nodeCfg,
  ...
}:
{
  imports = [
    ../modules/starr
  ];

  sops-vault.items = [ "starr" ];

  mares.starr = {
    enable = true;

    recyclarr = {
      enable = true;
      bindAddress = nodeCfg.host;
    };
  };
}
