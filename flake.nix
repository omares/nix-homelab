{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    flake-parts.url = "github:hercules-ci/flake-parts";

    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    deploy-rs.url = "github:serokell/deploy-rs";

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-sops-vault = {
      url = "git+ssh://git@github.com/omares/nix-sops-vault.git";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{
      self,
      flake-parts,
      nixpkgs,
      nixos-generators,
      deploy-rs,
      sops-nix,
      nix-sops-vault,
    }:
    let
      system = "aarch64-darwin";
      pkgs = nixpkgs.legacyPackages.${system};
    in
    flake-parts.lib.mkFlake { inherit inputs; } {

      systems =
        [
        ];
      flake =
        { config, ... }:
        {

          lib = import ./lib {
            inherit
              nixpkgs
              config
              sops-nix
              nix-sops-vault
              ;
            inherit (nixpkgs) lib;
          };

          packages.${system} = {
            # x86_64 VM template
            proxmox-x86 = import ./modules/virtualisation/proxmox-generator.nix {
              inherit nixos-generators nixpkgs;
              homelabLib = self.lib;
              system = "x86_64-linux";
            };

            # aarch64 VM template
            proxmox-arm = import ./modules/virtualisation/proxmox-generator.nix {
              inherit nixos-generators nixpkgs;
              homelabLib = self.lib;
              system = "aarch64-linux";
            };

            # Builder VM (x86_64) with arm support
            proxmox-builder = import ./modules/virtualisation/proxmox-generator.nix {
              inherit nixos-generators nixpkgs;
              homelabLib = self.lib;
              system = "x86_64-linux";
              extraModules = [
                config.nixosModules.role-builder
              ];
            };
          };

          devShells.${system} = {
            default = pkgs.mkShell {
              packages = with pkgs; [
                deploy-rs.packages.${system}.deploy-rs
                nixfmt-rfc-style
              ];
            };
          };

          _module.args = {
            homelabLib = self.lib;
          };

          nixosModules = {
            role-default = import ./modules/cluster/roles/default.nix;
            role-builder = import ./modules/cluster/roles/builder.nix;
            role-dns = import ./modules/cluster/roles/dns.nix;
            role-proxy = import ./modules/cluster/roles/proxy.nix;
          };

          imports = [
            ./modules/cluster/nodes.nix
          ];

          # nixosConfigurations = nixpkgs.lib.mapAttrs self.lib.mkNixosSystem config.cluster.nodes;
          nixosConfigurations =
            let
              managedNodes = nixpkgs.lib.filterAttrs (_: node: node.managed) config.cluster.nodes;
            in
            nixpkgs.lib.mapAttrs (
              name: nodeCfg:
              nixpkgs.lib.nixosSystem {
                inherit (nodeCfg) system;

                specialArgs = {
                  inherit nixpkgs nodeCfg name;
                  homelabLib = self.lib;
                  modulesPath = toString nixpkgs + "/nixos/modules";
                };

                modules = [
                  {
                    networking.hostName = name;
                  }
                  sops-nix.nixosModules.sops
                  nix-sops-vault.nixosModules.sops-vault
                  config.nixosModules.role-default
                ] ++ nodeCfg.roles;
              }
            ) managedNodes;

          deploy.nodes =
            let
              managedNodes = nixpkgs.lib.filterAttrs (_: node: node.managed) config.cluster.nodes;
            in
            nixpkgs.lib.mapAttrs (name: nodeCfg: {
              hostname = nodeCfg.host;

              profiles.system = {
                sshUser = nodeCfg.user;
                user = "root";
                interactiveSudo = true;
                remoteBuild = false;
                path = deploy-rs.lib.${nodeCfg.system}.activate.nixos self.nixosConfigurations.${name};
              };
            }) managedNodes;

          checks = builtins.mapAttrs (system: deployLib: deployLib.deployChecks self.deploy) deploy-rs.lib;

        };
    };
}
