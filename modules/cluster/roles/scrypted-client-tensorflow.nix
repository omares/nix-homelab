{
  pkgs,
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
    role = "client-tensorflow";
    serverHost = cluster.nodes.nvr-server-01.host;
    workerName = name;
  };

  environment.systemPackages = [
    pkgs.usbutils
    pkgs.libedgetpu
  ];
}
