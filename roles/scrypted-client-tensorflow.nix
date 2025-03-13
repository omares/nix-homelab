{
  pkgs,
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
    role = "client-tensorflow";
    serverHost = mares.nodes.nvr-server-01.host;
    workerName = name;
  };

  environment.systemPackages = [
    pkgs.usbutils
    pkgs.libedgetpu
  ];
}
