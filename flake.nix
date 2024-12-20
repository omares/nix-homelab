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
        {

          lib = import ./lib {
            inherit nixpkgs config;
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
                colmena.packages.${system}.colmena
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

          nixosConfigurations = nixpkgs.lib.mapAttrs self.lib.mkNixosSystem config.cluster.nodes;
        };
    };
}
