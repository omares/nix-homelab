{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nixpkgs-master.url = "github:nixos/nixpkgs/master";
    # nixpkgs 22.11 allows building Python 3.9 with TensorFlow without needing to override all dependent packages.
    nixpkgs-2211.url = "github:nixos/nixpkgs/nixos-22.11";

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
      nixpkgs-2211,
      nixos-generators,
      deploy-rs,
      sops-nix,
      nix-sops-vault,
    }:
    flake-parts.lib.mkFlake { inherit inputs; } {

      systems = [
        "x86_64-linux"
        "aarch64-darwin"
      ];

      imports = [
        ./modules/cluster
      ];
    };
}
