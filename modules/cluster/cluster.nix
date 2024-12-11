localFlake:

{
  lib,
  config,
  nixpkgs,
  ...
}:

with lib;
let
  availableRoles = builtins.attrNames (
    lib.filterAttrs (_: type: type == "directory") (builtins.readDir ../../roles)
  );

  mkNixosSystem =
    name: nodeCfg:
    nixpkgs.lib.nixosSystem {
      inherit (nodeCfg) system;
      modules = [
        {
          networking.hostName = name;
        }
        (map (role: ../../roles/${role}) nodeCfg.roles)
      ];
      specialArgs = {
        inherit (config) homelabLib;
      };
    };
in
{
  options.cluster = {
    nodes = mkOption {
      type = types.attrsOf (
        types.submodule {
          options = {
            system = mkOption {
              type = types.enum [
                "x86_64-linux"
                "aarch64-linux"
              ];
              default = "x86_64-linux";
              description = "Nodes system architecture";
            };

            roles = mkOption {
              type = types.listOf (types.enum availableRoles);
              default = [ ];
              description = "List of roles to apply on the node";
            };

            host = mkOption {
              type = types.ip;
              description = "IP address of the node";
            };

            user = mkOption {
              type = types.str;
              default = "omares";
              description = "User to deploy as";
            };
          };
        }
      );
      default = { };
    };
  };

  config = {
    nixosModules = lib.mapAttrs (

      name: nodeCfg: {
        inherit (nodeCfg) system;
        modules = [
          {
            networking.hostName = name;
          }
          (map (role: ../../roles/${role}) nodeCfg.roles)
        ];
        specialArgs = {
          # inherit (config) homelabLib;
        };
      }) config.cluster.nodes;
  };
  # config =
  # localFlake.nixosConfigurations = mapAttrs mkNixosSystem config.cluster.nodes;
}
