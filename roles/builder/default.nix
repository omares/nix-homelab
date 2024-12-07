{
  modulesPath,
  pkgs,
  lib,
  ...
}@args:
let
#  proxmoxTemplate = lib.getProxmoxTemplate pkgs.system;
in
{
  imports = [
#  proxmoxTemplate
    ../../modules/virtualisation/proxmox-builder.nix
    ../../modules/users/root.nix
  ];
}
