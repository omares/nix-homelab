{ lib }:
{
  roles = import ./roles.nix;
  getProxmoxTemplate = import ./get-proxmox-template.nix { inherit (lib.strings) splitString; };
  #    mkNode = import ./mkNode.nix { lib = final; };
}
