{
  lib,
}:
let
  self = {
    mkIfElse = import ./mkIfElse.nix {
      inherit (lib) mkMerge mkIf;
    };
  };
in
self
