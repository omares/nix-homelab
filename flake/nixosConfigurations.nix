{
  config,
  lib,
  inputs,
  ...
}:
let
  managedNodes = lib.filterAttrs (_: node: node.managed or false) config.mares.infrastructure.nodes;

  mkSystem =
    name: nodeCfg:
    inputs.nixpkgs.lib.nixosSystem {
      inherit (nodeCfg) system;

      specialArgs = {
        inherit
          inputs
          nodeCfg
          name
          ;
        inherit (config) mares;
        modulesPath = toString inputs.nixpkgs + "/nixos/modules";
      };

      modules = [
        {
          networking.hostName = name;
        }
        config.flake.nixosModules.role-default
      ] ++ nodeCfg.roles;
    };

in
{
  flake = {
    nixosConfigurations = lib.mapAttrs mkSystem managedNodes;
  };
}
