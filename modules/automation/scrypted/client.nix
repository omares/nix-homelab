{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.mares.automation.scrypted;
  isClient = cfg.cluster.mode == "client";

  plugins = pkgs.callPackage ../../../packages/scrypted/plugins { };

  # Known detection plugins that can run on cluster clients
  knownDetectionPlugins = [
    "openvino"
    "coreml"
    "onnx"
    "tensorflow-lite"
    "ncnn"
  ];

  # Filter user's plugins to only detection plugins
  requestedDetectionPlugins = lib.filter (p: lib.elem p knownDetectionPlugins) cfg.plugins;

  # Warn about non-detection plugins on client
  nonDetectionPlugins = lib.filter (p: !(lib.elem p knownDetectionPlugins)) cfg.plugins;
  nonDetectionWarnings =
    lib.optional (nonDetectionPlugins != [ ])
      "scrypted client: ignoring non-detection plugins (only run on server): ${lib.concatStringsSep ", " nonDetectionPlugins}";

  # Get packages for detection plugins
  detectionPkgs = map (name: plugins.${name}) requestedDetectionPlugins;

  # Build labels: compute + transcode + @scrypted/<plugin> + extraLabels
  pluginLabels = map (p: "@scrypted/${p}") requestedDetectionPlugins;
  labels = [
    "compute"
    "transcode"
  ]
  ++ pluginLabels
  ++ cfg.cluster.extraLabels;

  # Collect provisioning data from plugins
  mkRulesForPlugin =
    pkg:
    let
      pluginPath = "${cfg.installPath}/volume/plugins/${pkg.pluginName}";
    in
    lib.optionals (pkg ? provision) (
      [ "d ${pluginPath} 0755 ${cfg.user} ${cfg.group} -" ]
      ++ map (link: "L+ ${pluginPath}/${link.target} - - - - ${link.path}") (
        pkg.provision.symlinks or [ ]
      )
    );

  allTmpfiles = lib.concatMap mkRulesForPlugin detectionPkgs;
  pluginWarnings = lib.concatMap (pkg: (pkg.provision.warnings or [ ])) detectionPkgs;
  allWarnings = nonDetectionWarnings ++ pluginWarnings;
in
{
  config = lib.mkIf (cfg.enable && isClient) {
    warnings = allWarnings;

    systemd.services.scrypted.environment = {
      SCRYPTED_CLUSTER_MODE = "client";
      SCRYPTED_CLUSTER_SERVER = cfg.cluster.serverAddr;
      SCRYPTED_CLUSTER_WORKER_NAME = cfg.cluster.workerName;
      SCRYPTED_CLUSTER_LABELS = lib.concatStringsSep "," labels;
    };

    systemd.tmpfiles.rules = allTmpfiles;
  };
}
