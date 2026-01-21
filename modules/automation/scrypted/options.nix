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

    cluster = {
      mode = lib.mkOption {
        type = lib.types.enum [
          "server"
          "client"
        ];
        default = "server";
        description = "Cluster mode: server manages storage, client runs detection workloads";
      };

      serverAddr = lib.mkOption {
        type = lib.types.str;
        description = "Server: this machine's cluster address. Client: server address to connect to.";
      };

      workerName = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = "Human-readable worker name (client only)";
      };

      extraLabels = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "Additional cluster labels to add";
        example = [ "compute.preferred" ];
      };
    };

    plugins = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = ''
        Plugins to configure.
        - Server: all listed plugins are sideloaded via API
        - Client: only detection plugins (openvino, coreml, onnx, tensorflow-lite, ncnn)
          are provisioned locally; non-detection plugins are ignored with a warning
      '';
      example = [
        "nvr"
        "doorbird"
        "onvif"
        "openvino"
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
