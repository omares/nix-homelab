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

        SCRYPTED_CLUSTER_SERVER = lib.mkIf isClient cfg.serverHost;
        SCRYPTED_CLUSTER_WORKER_NAME = lib.mkIf isClient cfg.workerName;
      };
    in
    lib.mkIf cfg.enable {
      #
      # General / Mixed
      #

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

      users.users.scrypted.extraGroups =
        [
        ]
        ++ lib.optionals isOpenvinoClient [
          "video"
          "render"
        ]
        ++ lib.optionals isTensorflowClient [
          "podman"
          "coral"
        ];

      services.scrypted = lib.mkIf (isServer || isOpenvinoClient) {
        enable = true;
        package = pkgs.callPackage ../packages/scrypted.nix { };
        openFirewall = true;

        extraEnvironment = environment;
      };

      #
      # Server
      #

      fileSystems."/scrypted-fast" = lib.mkIf isServer {
        device = "/dev/disk/by-label/scrypted-fast";
        autoResize = true;
        fsType = "ext4";
      };

      cluster.storage.truenas.scrypted-large = lib.mkIf isServer {
        enable = true;
      };

      #
      # OpenVino
      #

      systemd.services.scrypted = lib.mkIf isOpenvinoClient {
        serviceConfig = {
          # Device access
          DeviceAllow = [
            "/dev/dri/renderD128"
            "/dev/dri/card1"
          ];
        };
      };

      cluster.hardware.intel-graphics = lib.mkIf isOpenvinoClient {
        enable = true;
      };

      #
      # Tensorflow
      #

      # The tensorflow client is runnig in a podman container as using Python 3.9 with libedgetpu is not possible on current Nix versions.
      # As such, the scrypted service configuration is not used, so we must replicate the user and group configuration.
      users.users.scrypted = {
        isSystemUser = true;
        group = config.services.scrypted.group;
        home = config.services.scrypted.installPath;
        createHome = true;
        description = "Scrypted service user";
        # linger = isTensorflowClient;
      };

      users.groups = lib.mkIf isTensorflowClient { ${config.services.scrypted.group} = { }; };

      hardware.coral = lib.mkIf isTensorflowClient {
        usb.enable = true;
      };

      services.udev.extraRules = lib.mkIf isTensorflowClient ''
        SUBSYSTEM=="usb", ATTRS{idVendor}=="1a6e", ATTRS{idProduct}=="089a", GROUP="coral", MODE="0666", TAG+="uaccess
        SUBSYSTEM=="usb", ATTRS{idVendor}=="18d1", ATTRS{idProduct}=="9302", GROUP="coral", MODE="0666", TAG+="uaccess
      '';

      virtualisation.oci-containers.containers."scrypted".environment =
        lib.mkIf isTensorflowClient environment;

    };
}
