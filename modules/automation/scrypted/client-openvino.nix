{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.mares.automation.scrypted;
  serviceCfg = config.mares.services.scrypted;
  isOpenvinoClient = cfg.role == "client-openvino";

  scrypted = pkgs.callPackage ../../../packages/scrypted/package.nix { };
  plugins = pkgs.callPackage ../../../packages/scrypted/plugins { };
  openvino = plugins.openvino;

  # Python platform directory name that Scrypted expects
  pythonPlatformDir = "python${openvino.pythonMajorMinor}-Linux-${openvino.platformArch}-${openvino.scryptedPythonVersion}";

  pluginPath = "${serviceCfg.installPath}/volume/plugins/${openvino.pluginName}";
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

    mares.services.scrypted = {
      enable = true;
      package = scrypted;
      openFirewall = true;
      extraEnvironment = {
        SCRYPTED_CLUSTER_LABELS = "compute,transcode,@scrypted/openvino";
        SCRYPTED_CLUSTER_MODE = "client";
        SCRYPTED_CLUSTER_SERVER = cfg.serverHost;
        SCRYPTED_CLUSTER_WORKER_NAME = cfg.workerName;
      };
      environmentFiles = [ config.sops.secrets.scrypted-environment.path ];
    };

    # Pre-provision OpenVINO plugin Python environment
    systemd.tmpfiles.rules = [
      "d ${pluginPath} 0755 ${serviceCfg.user} ${serviceCfg.group} -"
      "L+ ${pluginPath}/${pythonPlatformDir} - - - - ${openvino}/python-env"
    ];

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
  };
}
