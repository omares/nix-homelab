{
  modulesPath,
  pkgs,
  lib,
  ...
}@args:
let
in
#  proxmoxTemplate = lib.getProxmoxTemplate pkgs.system;
{
  imports = [
    #  proxmoxTemplate
    ../../modules/virtualisation/proxmox-builder.nix
    ../../modules/users/root.nix
  ];
}
