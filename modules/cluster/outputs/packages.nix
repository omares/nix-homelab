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
          imports = [ ../../virtualisation/format/proxmox-enhanced.nix ];

          formatAttr = "VMA";
          fileExtension = ".vma.zst";
        };
      };
      format = "proxmox-enhanced";
    };

in
{
  config.perSystem = {
    packages = {

      # x86_64 VM template
      proxmox-x86 = mkPackage {
        system = "x86_64-linux";
        extraModules = [ top.self.nixosModules.role-proxmox-legacy ];
      };

      # x86_64 VM template
      proxmox-x86-optimized = mkPackage {
        system = "x86_64-linux";
      };

      # aarch64 VM template
      proxmox-arm = mkPackage {
        system = "aarch64-linux";
        extraModules = [ top.self.nixosModules.role-proxmox-arm ];
      };

      # Builder VM (x86_64) with arm support
      proxmox-builder = mkPackage {
        system = "x86_64-linux";
        extraModules = [ top.self.nixosModules.role-proxmox-builder ];
      };

    };
  };
}
