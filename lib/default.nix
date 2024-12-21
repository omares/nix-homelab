{
  nixpkgs,
  config,
  lib,
  sops-nix,
  nix-sops-vault,
}:
let
  self = {
    mkIfElse = import ./mkIfElse.nix {
      inherit (lib) mkMerge mkIf;
    };
    mkNixosSystem = import ./mkNixosSystem.nix {
      inherit
        nixpkgs
        config
        sops-nix
        nix-sops-vault
        ;
      homelabLib = removeAttrs self [ "mkNixosSystem" ];
    };
  };
in
self
