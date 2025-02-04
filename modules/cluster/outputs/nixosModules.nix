{
  lib,
  ...
}:
let
  roles = lib.filterAttrs (name: type: type == "regular" && lib.hasSuffix ".nix" name) (
    builtins.readDir ../roles
  );

  mkModule = file: _: {
    name = "role-${lib.removeSuffix ".nix" file}";
    value = import (../roles + "/${file}");
  };
in
{
  flake = {
    nixosModules = lib.mapAttrs' mkModule roles;
  };
}
