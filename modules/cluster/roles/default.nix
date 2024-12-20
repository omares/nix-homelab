{
  modulesPath,
  ...
}:
{
  imports = [
    "${toString modulesPath}/virtualisation/proxmox-image.nix"
    ../../virtualisation/proxmox-default.nix
    ../../_all.nix
  ];

  # After a clean first-boot network setup managed by cloud-init,
  # we want to disable cloud-init for managed nodes.
  proxmox.cloudInit.enable = false;
  services.cloud-init.enable = false;
}
