{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.cluster.automation.scrypted;
in
{
  imports = [
    ../hardware/intel-graphics.nix
    ../services/scrypted.nix
    ../users/scrypted.nix
    ../storage/truenas.nix
  ];

  options.cluster.automation.scrypted = {
    enable = lib.mkEnableOption "Enable scrypted";

    role = lib.mkOption {
      type = lib.types.enum [
        "server"
        "client-openvino"
        "client-tensorflow"
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
      description = "Worker name used for client identifcation";
      default = "";
    };

  };

  config =
    let
      isServer = cfg.role == "server";
      isOpenvinoClient = cfg.role == "client-openvino";
      isTensorflowClient = cfg.role == "client-tensorflow";
      isClient = isOpenvinoClient || isTensorflowClient;

      clusterLabels = {
        "server" = "storage,";
        "client-openvino" = "compute,transcode,@scrypted/openvino";
        "client-tensorflow" = "compute,transcode,@scrypted/tensorflow-lite";
      };

      environment = {
        SCRYPTED_CLUSTER_SECRET = "dummy";
        SCRYPTED_CLUSTER_LABELS = clusterLabels.${cfg.role};

        SCRYPTED_CLUSTER_MODE = if isServer then "server" else "client";
        SCRYPTED_CLUSTER_ADDRESS = lib.mkIf isServer cfg.serverHost;

        # SCRYPTED_CLUSTER_SERVER = lib.mkIf isClient cfg.serverHost;
        SCRYPTED_CLUSTER_SERVER = lib.mkIf isClient cfg.serverHost;
        SCRYPTED_CLUSTER_WORKER_NAME = lib.mkIf isClient cfg.workerName;
      };
    in
    lib.mkIf cfg.enable {

      services.scrypted = {
        enable = true;
        package = pkgs.callPackage ../packages/scrypted.nix { };
        openFirewall = true;

        extraEnvironment = {
          SCRYPTED_CLUSTER_SECRET = "dummy";
          SCRYPTED_CLUSTER_LABELS = clusterLabels.${cfg.role};

          SCRYPTED_CLUSTER_MODE = if isServer then "server" else "client";
          SCRYPTED_CLUSTER_ADDRESS = lib.mkIf isServer cfg.serverHost;

          SCRYPTED_CLUSTER_SERVER = lib.mkIf isClient cfg.serverHost;
          SCRYPTED_CLUSTER_WORKER_NAME = lib.mkIf isClient cfg.workerName;
        };
      };

      fileSystems."/scrypted-fast" = lib.mkIf isServer {
        device = "/dev/disk/by-label/scrypted-fast";
        autoResize = true;
        fsType = "ext4";
      };

      cluster.storage.truenas.scrypted-large.enable = isServer;
      cluster.hardware.intel-graphics.enable = isOpenvinoClient;

      users.users.scrypted = {
        extraGroups =
          [
          ]
          ++ lib.optionals isOpenvinoClient [
            "video"
            "render"
          ]
          ++ lib.optionals isTensorflowClient [
            "coral"
          ];
      };

      systemd.services.scrypted = lib.mkIf isOpenvinoClient {
        serviceConfig = {
          # Device access
          DeviceAllow = [
            "/dev/dri/renderD128" # GPU render node for encoding/decoding
            "/dev/dri/card1" # Main GPU device for display/acceleration
          ];
        };
      };

      hardware.coral = {
        usb.enable = isTensorflowClient;
      };

      services.udev.extraRules = lib.mkIf isTensorflowClient ''
        SUBSYSTEM=="usb", ATTRS{idVendor}=="1a6e", ATTRS{idProduct}=="089a", GROUP="coral", MODE="0666"
        SUBSYSTEM=="usb", ATTRS{idVendor}=="18d1", ATTRS{idProduct}=="9302", GROUP="coral", MODE="0666"
      '';

      networking.firewall.enable = lib.mkForce false;

      # Used for communication between cluster servers and clients.
      networking.firewall = {
        allowedTCPPorts = lib.mkIf isServer [
          10556
        ];

        allowedTCPPortRanges = [
          {
            from = 32768;
            to = 60999;
          }
        ];
      };
    };
}
