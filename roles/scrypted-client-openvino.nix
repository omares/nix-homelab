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

  mares.hardware.intel-graphics.enable = true;

  # GPU access for scrypted user
  users.users.scrypted.extraGroups = [
    "video"
    "render"
  ];

  # Device access for GPU
  systemd.services.scrypted.serviceConfig.DeviceAllow = [
    "/dev/dri/renderD128"
    "/dev/dri/card1"
  ];

  mares.automation.scrypted = {
    enable = true;
    cluster.mode = "client";
    cluster.serverAddr = mares.infrastructure.nodes.nvr-server-01.dns.fqdn;
    cluster.workerName = name;
    plugins = [ "openvino" ];
  };
}
