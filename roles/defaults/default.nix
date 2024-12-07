{
  config,
  modulesPath,
  pkgs,
  lib,
  homelabLib,
  ...
}@args:
let
  #  myLib = specialArgs.lib;
  #  proxmoxTemplate = lib.getProxmoxTemplate pkgs.system;
  #  ourLib = import ../../lib { inherit (specialArgs) lib; };
  proxmoxTemplate = homelabLib.getProxmoxTemplate pkgs.system;
in
assert builtins.trace "defaults module evaluation started" true;
assert builtins.trace "homelabLib available: ${toString (homelabLib ? getProxmoxTemplate)}" true;
{
  imports = [
    "${toString modulesPath}/virtualisation/proxmox-image.nix"
    ../../modules/_all.nix
    proxmoxTemplate
  ];

  # After a clean first-boot network setup managed by cloud-init,
  # we want to disable cloud-init for managed nodes.
  proxmox.cloudInit.enable = false;
  services.cloud-init.enable = false;
}
