{
  lib,
  ...
}:
with lib;
let

in
{
  options.cluster = {
    proxy = {
      domain = mkOption {
        type = types.str;
        description = "Base domain for all services";
      };
    };
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
                  config.flake.nixosModules.role-dns
                  config.flake.nixosModules.role-builder
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

            proxy = mkOption {
              type = types.nullOr (
                types.submodule {
                  options = {
                    port = mkOption {
                      type = types.port;
                      description = "Target port";
                    };

                    subdomains = mkOption {
                      type = types.listOf types.str;
                      default = [ ];
                      description = "Additional subdomains for this service";
                    };

                    protocol = mkOption {
                      type = types.enum [
                        "http"
                        "https"
                      ];
                      default = "http";
                      description = "Protocol to use in proxy address";
                    };

                    websockets = mkOption {
                      type = types.bool;
                      default = false;
                      description = "Whether to support proxying websocket connections with HTTP/1.1.";
                    };

                    ssl = mkOption {
                      type = types.bool;
                      default = true;
                      description = "Enable SSL for this service";
                    };

                    extraConfig = mkOption {
                      type = types.lines;
                      default = "";
                      description = "Additional nginx configuration for this virtual host";
                    };
                  };
                }
              );
              default = null;
              description = "Proxy configuration for this node";
            };

          };
        }
      );
      default = { };
    };

  };
}
