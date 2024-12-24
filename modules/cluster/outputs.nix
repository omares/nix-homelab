{
  config,
  lib,
  inputs,
  ...
}:
{

  config.flake =
    let
      managedNodes = lib.filterAttrs (_: node: node.managed or false) config.cluster.nodes;

      roles = lib.filterAttrs (name: type: type == "regular" && lib.hasSuffix ".nix" name) (
        builtins.readDir ./roles
      );

      mkModule = file: _: {
        name = "role-${lib.removeSuffix ".nix" file}";
        value = import (./roles + "/${file}");
      };

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
            homelabLib = config.flake.lib;
            modulesPath = toString inputs.nixpkgs + "/nixos/modules";
          };

          modules = [
            {
              networking.hostName = name;
            }
            inputs.sops-nix.nixosModules.sops
            inputs.nix-sops-vault.nixosModules.sops-vault
            config.flake.nixosModules.role-default
          ] ++ nodeCfg.roles;
        };

      mkDeployNode = name: nodeCfg: {

        hostname = nodeCfg.host;

        profiles.system = {
          sshUser = nodeCfg.user;
          user = "root";
          interactiveSudo = true;
          remoteBuild = false;
          fastConnection = true;
          path =
            inputs.deploy-rs.lib.${nodeCfg.system}.activate.nixos
              config.flake.nixosConfigurations.${name};
        };
      };
    in
    {
      nixosModules = lib.mapAttrs' mkModule roles;

      nixosConfigurations = lib.mapAttrs mkSystem managedNodes;

      deploy.nodes = lib.mapAttrs mkDeployNode managedNodes;

      checks = builtins.mapAttrs (
        system: deployLib: deployLib.deployChecks config.flake.deploy
      ) inputs.deploy-rs.lib;
    };
}
