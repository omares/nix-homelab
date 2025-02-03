{
  config,
  lib,
  inputs,
  ...
}:
let
  managedNodes = lib.filterAttrs (_: node: node.managed or false) config.cluster.nodes;

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
        inherit (config) cluster;
        modulesPath = toString inputs.nixpkgs + "/nixos/modules";
      };

      modules = [
        {
          networking.hostName = name;
        }
        config.flake.nixosModules.role-default
        ../../users/ids.nix

      ] ++ nodeCfg.roles;
    };

in
{
  config.flake = {
    nixosConfigurations = lib.mapAttrs mkSystem managedNodes;
  };
}
