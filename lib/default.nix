{ lib }:
let
  roles = import ./roles.nix;
in
{
  roles = roles;
  mkNode = import ./mkNode.nix {
    inherit (lib) mkIf;
    availableRoles = roles;
  };
}
