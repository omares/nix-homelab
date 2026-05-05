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

    seerr = {
      enable = true;
      user = "jellyseerr";
      bindAddress = nodeCfg.host;
    };
  };
}
