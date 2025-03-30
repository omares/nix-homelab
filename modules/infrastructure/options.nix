{
  lib,
  ...
}:
{
  options.mares.infrastructure = {
    lib = lib.mkOption {
      type = lib.types.attrs;
      default = import ../../lib {
        inherit lib;
      };
      description = "Custom library functions.";
    };

    proxy = {
      domain = lib.mkOption {
        type = lib.types.str;
        description = "Base domain for all services";
      };
    };

    nodes = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule {
          options = {
            managed = lib.mkOption {
              type = lib.types.bool;
              default = true;
              description = "Whether this node is managed by the deployment tool";
            };

            system = lib.mkOption {
              type = lib.types.enum [
                "x86_64-linux"
                "aarch64-linux"
              ];
              default = "x86_64-linux";
              description = "Nodes system architecture";
            };

            roles = lib.mkOption {
              type = lib.types.listOf (
                lib.types.attrs
                // {
                  check =
                    val: lib.isFunction val || lib.isAttrs val && (val ? imports || val ? config || val ? options);
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

            host = lib.mkOption {
              type = lib.types.str;
              description = "IP address of the node";
            };

            user = lib.mkOption {
              type = lib.types.str;
              default = "omares";
              description = "User to deploy as";
            };

            proxy = lib.mkOption {
              type = lib.types.nullOr (
                lib.types.submodule {
                  options = {
                    port = lib.mkOption {
                      type = lib.types.port;
                      description = "Target port";
                    };

                    subdomains = lib.mkOption {
                      type = lib.types.listOf lib.types.str;
                      default = [ ];
                      description = "Additional subdomains for this service";
                    };

                    protocol = lib.mkOption {
                      type = lib.types.enum [
                        "http"
                        "https"
                      ];
                      default = "http";
                      description = "Protocol to use in proxy address";
                    };

                    websockets = lib.mkOption {
                      type = lib.types.bool;
                      default = false;
                      description = "Whether to support proxying websocket connections with HTTP/1.1.";
                    };

                    ssl = lib.mkOption {
                      type = lib.types.bool;
                      default = true;
                      description = "Enable SSL for this service";
                    };

                    extraConfig = lib.mkOption {
                      type = lib.types.lines;
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
