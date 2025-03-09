top@{
  config,
  lib,
  inputs,
  self,
  ...
}:
let
  mkPackage =
    {
      system,
      extraModules ? [ ],
    }:

    inputs.nixos-generators.nixosGenerate {
      # system = "x86_64-linux";
      inherit system;

      modules = [
        { nix.registry.nixpkgs.flake = inputs.nixpkgs; }
        top.self.nixosModules.role-default
        {
          # Ensure that cloud-init is enabled for the generated VMs.
          proxmox-enhanced.cloudInit.enable = lib.mkForce true;
          services.cloud-init.enable = lib.mkForce true;
        }
      ] ++ extraModules;

      specialArgs = {
        homelabLib = lib;
        inherit inputs;
      };

      customFormats = {
        "proxmox-enhanced" = {
          imports = [ ../modules/virtualisation/format/proxmox-enhanced.nix ];

          formatAttr = "VMA";
          fileExtension = ".vma.zst";
        };
      };
      format = "proxmox-enhanced";
    };

in
{
  perSystem =
    {
      pkgs,
      ...
    }:
    {
      packages = {
        # x86_64 VM template
        proxmox-x86-legacy = mkPackage {
          system = "x86_64-linux";
          extraModules = [ top.self.nixosModules.role-proxmox-legacy ];
        };

        # x86_64 VM template
        proxmox-x86-optimized = mkPackage {
          system = "x86_64-linux";
        };

        # Builder VM (x86_64) with arm support
        proxmox-x86-builder = mkPackage {
          system = "x86_64-linux";
          extraModules = [ top.self.nixosModules.role-proxmox-builder ];
        };

        # aarch64 VM template
        proxmox-arm = mkPackage {
          system = "aarch64-linux";
          extraModules = [ top.self.nixosModules.role-proxmox-arm ];
        };

        # scrypted package
        scrypted = import ../modules/packages/scrypted.nix {

          inherit (pkgs)
            lib
            buildNpmPackage
            fetchFromGitHub
            nodejs_20
            callPackage
            nix-update-script
            ;
        };
      };
    };
}
