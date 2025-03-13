{
  lib,
  config,
  mares,
  ...
}:

with lib;
let
  arrServiceOpts =
    { name, ... }:
    {
      options = {
        enable = mkEnableOption "Enable ${name} service";

        mountStorage = mkEnableOption "Moun Truenas storage.";

        user = mkOption {
          type = types.str;
          default = name;
          description = "User to run ${name} as";
        };

        bindAddress = lib.mkOption {
          type = lib.types.str;
          description = "Address to bind the ${name} service to";
        };
      };
    };

in
{
  options.mares.services.starr = {
    enable = mkEnableOption "Enable starr services";

    group = mkOption {
      type = types.str;
      default = "starr";
      description = "Group used for all starr services";
    };

    pathPrefix = mkOption {
      type = types.path;
      default = "/var/lib";
      description = "Base path for starr services data";
    };

    postgres = {
      host = lib.mkOption {
        type = lib.types.str;
        default = mares.nodes.db-01.host;
        description = "PostgreSQL host address";
      };

      port = lib.mkOption {
        type = lib.types.port;
        default = config.services.pgbouncer.settings.pgbouncer.listen_port;
        description = "PostgreSQL port";
      };
    };

    sabnzbd = mkOption {
      type = types.submodule arrServiceOpts;
      default = { };
      description = "Sabnzbd service configuration";
    };

    prowlarr = mkOption {
      type = types.submodule arrServiceOpts;
      default = { };
      description = "Prowlarr service configuration";
    };

    sonarr = mkOption {
      type = types.submodule arrServiceOpts;
      default = { };
      description = "Sonarr service configuration";
    };

    radarr = mkOption {
      type = types.submodule arrServiceOpts;
      default = { };
      description = "Radarr service configuration";
    };

    recyclarr = mkOption {
      type = types.submodule arrServiceOpts;
      default = { };
      description = "Recyclarr service configuration";
    };

    jellyfin = mkOption {
      type = types.submodule arrServiceOpts;
      default = { };
      description = "Jellyfin service configuration";
    };

    jellyseerr = mkOption {
      type = types.submodule arrServiceOpts;
      default = { };
      description = "Jellyseerr service configuration";
    };
  };
}
