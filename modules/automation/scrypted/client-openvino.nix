{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.cluster.automation.scrypted;
  isOpenvinoClient = cfg.role == "client-openvino";
in
{
  config = lib.mkIf (cfg.enable && isOpenvinoClient) {
    users.users.scrypted.extraGroups = [
      "video"
      "render"
    ];

    services.scrypted = {
      enable = true;
      package = pkgs.callPackage ../../packages/scrypted.nix { };
      openFirewall = true;
      extraEnvironment = {
        SCRYPTED_CLUSTER_LABELS = "compute,transcode,@scrypted/openvino";
        SCRYPTED_CLUSTER_MODE = "client";
        SCRYPTED_CLUSTER_SERVER = cfg.serverHost;
        SCRYPTED_CLUSTER_WORKER_NAME = cfg.workerName;
      };
      environmentFiles = [ config.sops.secrets.scrypted-environment.path ];
    };

    systemd.services.scrypted = {
      wants = [
        "sops-nix.service"
      ];
      after = [
        "sops-nix.service"
      ];

      serviceConfig.DeviceAllow = [
        "/dev/dri/renderD128"
        "/dev/dri/card1"
      ];
    };

    cluster.hardware.intel-graphics.enable = true;
  };
}
