{
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";

    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    colmena = {
      url = "github:zhaofengli/colmena";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      nixos-generators,
      colmena,
    }:
    let
      system = "aarch64-darwin";
      pkgs = nixpkgs.legacyPackages.${system};
    in
    {
      lib = import ./lib { inherit (nixpkgs) lib; };
      packages.${system} = {
        # x86_64 VM template
        proxmox-x86 = import ./modules/virtualisation/proxmox-template.nix {
          inherit nixos-generators nixpkgs;
          homelabLib = self.lib;
          system = "x86_64-linux";
        };

        # aarch64 VM template
        proxmox-arm = import ./modules/virtualisation/proxmox-template.nix {
          inherit nixos-generators nixpkgs;
          homelabLib = self.lib;
          system = "aarch64-linux";
        };

        # Builder VM (x86_64) with arm support
        proxmox-builder = import ./modules/virtualisation/proxmox-template.nix {
          inherit nixos-generators nixpkgs;
          homelabLib = self.lib;
          system = "x86_64-linux";
          extraModules = [
            ./roles/${self.lib.roles.builder}
          ];
        };
      };

      devShells.${system}.default = pkgs.mkShell {
        packages = with pkgs; [
          colmena.packages.${system}.colmena
          nixfmt-rfc-style
        ];
      };
      #
      #      colmena = import ./roles {
      #        inherit nixpkgs;
      #        homelabLib = self.lib;
      #      };

      colmena = {
        meta = {
          nixpkgs = import nixpkgs {
            system = "x86_64-linux";
          };

          _module.args = {
            homelabLib = self.lib;
          };
        };

        defaults = {
          deployment = {
            targetUser = "omares";
          };
          imports = [
            ./roles/defaults
          ];
        };

        build-01 = {
          deployment = {
            targetHost = "192.168.20.224";
          };
          imports = [
            ./roles/builder
          ];
        };
      };
    };
}
