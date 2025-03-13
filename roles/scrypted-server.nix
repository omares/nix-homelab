{
  nodeCfg,
  ...
}:
{
  imports = [
    ../modules/automation/scrypted
  ];

  mares.automation.scrypted = {
    enable = true;
    role = "server";
    serverHost = nodeCfg.host;
  };
}
