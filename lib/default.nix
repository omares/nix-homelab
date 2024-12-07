{ lib }:
{
  roles = import ./roles.nix;
  # when passing down lib = final to get-proxmox-template i end up in an infite recusion
  getProxmoxTemplate = import ./get-proxmox-template.nix { inherit (lib.strings) splitString; };
#    mkNode = import ./mkNode.nix { lib = final; };
}
