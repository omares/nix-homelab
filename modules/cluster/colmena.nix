{
  config,
  lib,
  # nixpkgs,
  # nix-sops-vault,
  # sops-nix,
  # pkgs,
  ...
}:

with lib;
let
  managedNodes = filterAttrs (_: node: node.managed) config.cluster.nodes;

  mkColmenaNode = name: nodeCfg: {
    deployment = {
      targetUser = nodeCfg.user;
      targetHost = nodeCfg.host;
      tags = [ name ] ++ (builtins.filter (role: role != "defauls") nodeCfg.roles);
    };

    networking.hostName = name;

    imports =
      map (role: ../../roles/${role}) nodeCfg.roles
      ++ nodeCfg.imports
      ++ optional (nodeCfg.sops-vault != [ ]) ../security/sops.nix;

    sops-vault.items = mkIf (nodeCfg.sops-vault != [ ]) nodeCfg.sops-vault;
  };
in
{
  imports = [
    ../../roles
  ];
  options = {
    cluster.nodes = mkOption {
      type = types.attrsOf (
        types.submodule {
          options = {
            managed = mkOption {
              type = types.bool;
              default = true;
              description = "Whether this node should be managed by colmena";
            };

            sops-vault = mkOption {
              type = types.listOf types.str;
              default = [ ];
              description = "Sops entries that will be availble in node configuration";
            };

            imports = mkOption {
              type = types.listOf types.anything;
              default = [ ];
              description = "Additional configurations to import for this node";
            };
          };
        }
      );
    };
  };

  # config = {

  #   colmena = mapAttrs mkColmenaNode managedNodes // {
  #     meta = {
  #       nixpkgs = pkgs;

  #       specialArgs = {
  #         inherit
  #           homelabLib
  #           sops-nix
  #           nix-sops-vault
  #           ;
  #       };
  #     };
  #   };
  # };
}
