{
  name,
  cluster,
  ...
}:
{
  imports = [
    ../../automation/scrypted.nix
  ];

  cluster.automation.scrypted = {
    enable = true;
    role = "client-openvino";
    serverHost = cluster.nodes.nvr-server-01.host;
    workerName = name;
  };
}
