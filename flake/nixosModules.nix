{
  lib,
  ...
}:
let
  roles = lib.filterAttrs (name: type: type == "regular" && lib.hasSuffix ".nix" name) (
    builtins.readDir ../modules/cluster/roles
  );

  mkModule = file: _: {
    name = "role-${lib.removeSuffix ".nix" file}";
    value = import (../modules/cluster/roles + "/${file}");
  };
in
{
  flake = {
    nixosModules = lib.mapAttrs' mkModule roles;
  };
}
