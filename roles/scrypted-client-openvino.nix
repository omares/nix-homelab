{
  name,
  mares,
  ...
}:
{
  imports = [
    ../modules/hardware/intel-graphics.nix
    ../modules/automation/scrypted
  ];

  sops-vault.items = [ "scrypted" ];

  mares.hardware.intel-graphics = {
    enable = true;
  };

  mares.automation.scrypted = {
    enable = true;
    role = "client-openvino";
    serverHost = mares.infrastructure.nodes.nvr-server-01.dns.fqdn;
    workerName = name;
  };
}
