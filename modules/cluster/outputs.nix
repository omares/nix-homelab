top@{
  config,
  lib,
  inputs,
  self,
  ...
}:
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
        modulesPath = toString inputs.nixpkgs + "/nixos/modules";
      };

      modules = [
        {
          networking.hostName = name;
        }
        config.flake.nixosModules.role-default
        ../users/ids.nix

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

  config.flake = {
    nixosModules = lib.mapAttrs' mkModule roles;

    nixosConfigurations = lib.mapAttrs mkSystem managedNodes;

    deploy.nodes = lib.mapAttrs mkDeployNode managedNodes;

    checks = builtins.mapAttrs (
      system: deployLib: deployLib.deployChecks config.flake.deploy
    ) inputs.deploy-rs.lib;
  };

  config.perSystem = {
    packages = {

      # x86_64 VM template
      proxmox-x86-optimized = inputs.nixos-generators.nixosGenerate {
        system = "x86_64-linux";

        modules = [
          { nix.registry.nixpkgs.flake = inputs.nixpkgs; }
          top.self.nixosModules.role-default
          {
            # Ensure that cloud-init is enabled for the generated VMs.
            proxmox-enhanced.cloudInit.enable = lib.mkForce true;
            services.cloud-init.enable = lib.mkForce true;
          }
        ];

        specialArgs = {
          homelabLib = lib;
          inherit inputs;
        };

        customFormats = {
          "proxmox-enhanced" = {
            imports = [ ../virtualisation/format/proxmox-enhanced.nix ];

            formatAttr = "VMA";
            fileExtension = ".vma.zst";
          };
        };
        format = "proxmox-enhanced";
      };
    };
  };
}
