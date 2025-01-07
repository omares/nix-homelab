{
  lib,
}:
let
  self = {
    mkIfElse = import ./mkIfElse.nix {
      inherit (lib) mkMerge mkIf;
    };

    generators = import ./generators.nix {
      inherit (lib.strings) fixedWidthString isString;
      inherit (lib.generators) toINIWithGlobalSection mkKeyValueDefault;
      inherit (lib) concatStringsSep mapAttrsToList isAttrs;
    };
  };
in
self
