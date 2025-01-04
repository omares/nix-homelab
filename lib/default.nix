{
  lib,
}:
let
  self = {
    mkIfElse = import ./mkIfElse.nix {
      inherit (lib) mkMerge mkIf;
    };

    generators = import ./generators.nix {
      inherit (lib.strings) fixedWidthString;
      inherit (lib) concatStringsSep mapAttrsToList;
    };
  };
in
self
