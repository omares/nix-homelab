{ lib }:
let
  roles = import ./roles.nix;
in
{
  roles = roles;
  mkIfElse = import ./mkIfElse.nix {
    inherit (lib) mkMerge mkIf;
  };
  mkNode = import ./mkNode.nix {
    inherit (lib) mkIf;
    availableRoles = roles;
  };
}
