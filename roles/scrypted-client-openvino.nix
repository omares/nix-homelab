{
  name,
  mares,
  ...
}:
{
  imports = [
    ../modules/automation/scrypted
  ];

  mares.automation.scrypted = {
    enable = true;
    role = "client-openvino";
    serverHost = mares.nodes.nvr-server-01.host;
    workerName = name;
  };
}
