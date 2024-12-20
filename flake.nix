{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    flake-parts.url = "github:hercules-ci/flake-parts";

    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    colmena = {
      url = "github:zhaofengli/colmena";
      inputs.nixpkgs.follows = "nixpkgs";
    };

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
      colmena,
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
        let
          mkNixosSystem =
            name: nodeCfg:
            nixpkgs.lib.nixosSystem {
              inherit (nodeCfg) system;

              specialArgs = {
                inherit nixpkgs;
                modulesPath = toString nixpkgs + "/nixos/modules";
                homelabLib = self.lib;

              };

              modules = [
                {
                  networking.hostName = name;
                }
                ./roles/defaults

              ] ++ (map (role: ./roles/${role}) nodeCfg.roles);
            };
        in
        {

          lib = import ./lib {
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
                ./roles/${self.lib.roles.builder}
              ];
            };
          };

          devShells.${system} = {
            default = pkgs.mkShell {
              packages = with pkgs; [
                colmena.packages.${system}.colmena
                nixfmt-rfc-style
              ];
            };
          };

          imports = [
            ./modules/cluster/cluster.nix
            ./modules/cluster/colmena.nix
            ./roles
          ];

          nixosConfigurations = nixpkgs.lib.mapAttrs mkNixosSystem config.cluster.nodes;

          # imports = [
          #   # inputs.flake-parts.flakeModules.flakeModules
          #   # (flake-parts.lib.importApply ./modules/cluster/cluster.nix { homelabLib = self.lib; })
          #   ./modules/cluster/cluster.nix
          #   # ./modules/cluster/colmena.nix
          #   (flake-parts.lib.importApply ./modules/cluster/colmena.nix)
          #   ./roles
          # ];

          _module.args = {
            homelabLib = self.lib;
          };

          # nixosConfigurations =
          #   (nixpkgs.lib.evalModules {
          #     modules = [
          #       ./roles
          #     ];
          #     specialArgs = {
          #       inherit nixpkgs sops-nix;
          #       homelabLib = self.lib;
          #     };
          #   }).config.nixosConfigurations;

          # colmena = import ./modules/cluster/colmena.nix {
          #   inherit nixpkgs sops-nix nix-sops-vault;
          #   inherit (nixpkgs) lib;
          #   homelabLib = self.lib;

          #   # config = self.cluster;
          # };
        };
    };
}
