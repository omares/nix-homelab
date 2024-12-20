{
  nixpkgs,
  config,
  lib,
}:
let
  self = {
    mkIfElse = import ./mkIfElse.nix {
      inherit (lib) mkMerge mkIf;
    };
    mkNixosSystem = import ./mkNixosSystem.nix {
      inherit nixpkgs config;
      homelabLib = removeAttrs self [ "mkNixosSystem" ];
    };
  };
in
self
