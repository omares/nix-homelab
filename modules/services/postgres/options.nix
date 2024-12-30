{
  lib,
  ...
}:
{
  options.cluster.db.postgres = {
    enable = lib.mkEnableOption "PostgreSQL and PgBouncer setup";

    users = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule {
          options = {
            name = lib.mkOption {
              type = lib.types.str;
              description = "Name of the database user";
            };

            ensureDBOwnership = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = "Whether the user should own a database with the same name";
            };

            createdb = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = "Whether the user can create databases";
            };

            peer = lib.mkOption {
              type = lib.types.nullOr (
                lib.types.oneOf [
                  lib.types.str
                  (lib.types.listOf lib.types.str)
                ]
              );
              default = null;
              description = "IP address or list of IP addresses from which this user can connect";
              example = "192.168.1.100";
            };
          };
        }
      );
      default = { };
      description = "Attribute set of database users to create";
      example = lib.literalExpression ''
        {
          prowlarr = {
            ensureDBOwnership = true;
            createdb = false;
            peer = "192.168.1.100";
          };
          radarr = {
            ensureDBOwnership = true;
            createdb = false;
            peer = [ "192.168.1.101" "192.168.1.102" ];
          };
        }
      '';
    };

    databases = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule {
          name = lib.mkOption {
            type = lib.types.str;
            description = "Name of the database";
          };
        }
      );
      default = { };
      description = "Attribute set of databases to create";
      example = lib.literalExpression ''
        {
          prowlarr = {};
          radarr = {};
        }
      '';
    };

    adminUser = lib.mkOption {
      type = lib.types.str;
      default = "omares";
      description = "Name of the admin user with superuser privileges";
    };

    listenAddress = lib.mkOption {
      type = lib.types.str;
      description = "IP address where PostgreSQL and PgBouncer will listen and allow connections from by default";
      example = "192.168.1.10";
    };
  };
}
