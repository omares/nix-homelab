{
  lib,
  ...
}:
with lib;
let

in
{
  options.cluster = {
    nodes = mkOption {
      type = types.attrsOf (
        types.submodule {
          options = {
            managed = mkOption {
              type = types.bool;
              default = true;
              description = "Whether this node is managed by the deployment tool";
            };

            system = mkOption {
              type = types.enum [
                "x86_64-linux"
                "aarch64-linux"
              ];
              default = "x86_64-linux";
              description = "Nodes system architecture";
            };

            roles = mkOption {
              type = types.listOf (
                types.attrs
                // {
                  check = val: isFunction val || isAttrs val && (val ? imports || val ? config || val ? options);
                  description = "valid NixOS module";
                }
              );
              default = [ ];
              description = "List of roles to apply to the node. Must be NixOS module references";
              example = ''
                [
                  config.nixosModules.role-dns
                  config.nixosModules.role-builder
                ]
              '';
            };

            host = mkOption {
              type = types.str;
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
}
