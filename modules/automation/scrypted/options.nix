{
  lib,
  pkgs,
  ...
}:
let
  scrypted = pkgs.callPackage ../../../packages/scrypted/package.nix { };
in
{
  options.mares.automation.scrypted = {
    enable = lib.mkEnableOption "Scrypted home automation server";

    role = lib.mkOption {
      type = lib.types.enum [
        "server"
        "client-openvino"
      ];
      default = "server";
      description = "Role of this Scrypted instance";
    };

    serverHost = lib.mkOption {
      type = lib.types.str;
      description = "Address of the server host";
    };

    workerName = lib.mkOption {
      type = lib.types.str;
      description = "Worker name used for client identification";
      default = "";
    };

    plugins = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "List of Scrypted plugins to pre-install via sideloading (server only)";
      example = [
        "nvr"
        "doorbird"
        "onvif"
      ];
    };

    package = lib.mkOption {
      type = lib.types.package;
      default = scrypted;
      description = "The scrypted package to use";
    };

    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Open firewall ports for Scrypted";
    };

    installPath = lib.mkOption {
      type = lib.types.path;
      default = "/var/lib/scrypted";
      description = "Directory where scrypted data will be stored";
    };

    user = lib.mkOption {
      type = lib.types.str;
      default = "scrypted";
      description = "User account under which scrypted runs";
    };

    group = lib.mkOption {
      type = lib.types.str;
      default = "scrypted";
      description = "Group account under which scrypted runs";
    };

    environmentFiles = lib.mkOption {
      type = lib.types.listOf lib.types.path;
      default = [ ];
      description = "Environment files to pass to service.";
      example = [
        "/run/secrets/scrypted-environment"
      ];
    };
  };
}
