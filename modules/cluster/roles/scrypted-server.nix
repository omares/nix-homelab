{
  nodeCfg,
  ...
}:
{
  imports = [
    ../../automation/scrypted.nix
  ];

  cluster.automation.scrypted = {
    enable = true;
    role = "server";
    serverHost = nodeCfg.host;
  };
}
