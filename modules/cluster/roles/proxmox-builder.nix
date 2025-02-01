{
  lib,
  ...
}:
{
  imports = [
    ../../users/builder-root.nix
  ];

  cluster.vm-profile.template = lib.mkForce "proxmox-builder";
}
