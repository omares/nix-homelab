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
        "x86_64-linux"
        "aarch64-darwin"
      ];

      imports = [
        ./modules/cluster
      ];

      flake = {

        lib = import ./lib {
          inherit (nixpkgs) lib;
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
