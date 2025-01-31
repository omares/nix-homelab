{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nixpkgs-master.url = "github:nixos/nixpkgs/master";

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
      nixpkgs-master,
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

      systems = [
      ];

      # Creates 'nixosModels', 'nixosConfigurations', 'deploy.nodes', and 'check' outputs
      # based on defined nodes in ./modules/cluster/nodes.nix and existing roles in ./modules/cluster/roles.
      imports = [
        ./modules/cluster
      ];

      flake =
        { config, ... }:
        {

          lib = import ./lib {
            inherit (nixpkgs) lib;
          };

          # todo: Move packages to own module
          packages.${system} = {
            # x86_64 VM template
            proxmox-x86 = import ./modules/virtualisation/proxmox-generator.nix {
              inherit nixos-generators nixpkgs;
              homelabLib = self.lib;
              system = "x86_64-linux";
            };

            # x86_64 VM template
            proxmox-x86-custom = import ./modules/virtualisation/proxmox-generator-custom.nix {
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

          packages.x86_64-linux =
            let
              x86pkgs = nixpkgs.legacyPackages."x86_64-linux";
            in
            {
              scrypted = import ./modules/packages/scrypted.nix {

                inherit (x86pkgs)
                  lib
                  buildNpmPackage
                  fetchFromGitHub
                  nodejs_20
                  callPackage
                  ;
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
        };
    };
}
