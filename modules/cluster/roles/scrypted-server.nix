{
  nodeCfg,
  ...
}:
{
  imports = [
    ../../automation/scrypted
  ];

  cluster.automation.scrypted = {
    enable = true;
    role = "server";
    serverHost = nodeCfg.host;
  };
}
