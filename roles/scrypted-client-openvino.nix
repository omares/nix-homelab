{
  name,
  cluster,
  ...
}:
{
  imports = [
    ../modules/automation/scrypted
  ];

  cluster.automation.scrypted = {
    enable = true;
    role = "client-openvino";
    serverHost = cluster.nodes.nvr-server-01.host;
    workerName = name;
  };
}
