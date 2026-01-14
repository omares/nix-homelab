{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.mares.automation.scrypted;
  isOpenvinoClient = cfg.role == "client-openvino";

  plugins = pkgs.callPackage ../../../packages/scrypted/plugins { };
  openvino = plugins.openvino;

  # Python platform directory name that Scrypted expects
  pythonPlatformDir = "python${openvino.pythonMajorMinor}-Linux-${openvino.platformArch}-${openvino.scryptedPythonVersion}";

  pluginPath = "${cfg.installPath}/volume/plugins/${openvino.pluginName}";
in
{
  config = lib.mkIf (cfg.enable && isOpenvinoClient) {
    warnings = [
      "scrypted-openvino: Requires internet access to download ML models on first use"
    ];

    users.users.scrypted.extraGroups = [
      "video"
      "render"
    ];

    systemd.services.scrypted = {
      environment = {
        SCRYPTED_CLUSTER_LABELS = "compute,transcode,@scrypted/openvino";
        SCRYPTED_CLUSTER_MODE = "client";
        SCRYPTED_CLUSTER_SERVER = cfg.serverHost;
        SCRYPTED_CLUSTER_WORKER_NAME = cfg.workerName;
      };

      serviceConfig.DeviceAllow = [
        "/dev/dri/renderD128"
        "/dev/dri/card1"
      ];
    };

    # Pre-provision OpenVINO plugin Python environment
    systemd.tmpfiles.rules = [
      "d ${pluginPath} 0755 ${cfg.user} ${cfg.group} -"
      "L+ ${pluginPath}/${pythonPlatformDir} - - - - ${openvino}/python-env"
    ];
  };
}
