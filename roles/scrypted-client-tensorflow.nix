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

  sops-vault.items = [ "scrypted" ];

  mares.automation.scrypted = {
    enable = true;
    role = "client-tensorflow";
    serverHost = mares.infrastructure.nodes.nvr-server-01.dns.fqdn;
    workerName = name;
  };

  environment.systemPackages = [
    pkgs.usbutils
    pkgs.libedgetpu
  ];
}
