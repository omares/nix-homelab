{
  pkgs,
  name,
  cluster,
  ...
}:
{
  imports = [
    ../../automation/scrypted
  ];

  cluster.automation.scrypted = {
    enable = true;
    role = "client-tensorflow";
    serverHost = cluster.nodes.nvr-server-01.host;
    workerName = name;
  };

  environment.systemPackages = [
    pkgs.usbutils
    pkgs.libedgetpu
  ];
}
