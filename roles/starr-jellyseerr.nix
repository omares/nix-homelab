{
  nodeCfg,
  ...
}:
{

  imports = [
    ../modules/starr
  ];

  sops-vault.items = [
    "starr"
    "pgsql"
  ];

  mares.starr = {
    enable = true;

    jellyseerr = {
      enable = true;
      bindAddress = nodeCfg.host;
    };
  };
}
