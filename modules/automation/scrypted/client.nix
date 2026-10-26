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

  # Filter user's plugins to only detection plugins
  requestedDetectionPlugins = lib.filter (p: lib.elem p cfg.detectionPlugins) cfg.plugins;

  # Warn about non-detection plugins on client
  nonDetectionPlugins = lib.filter (p: !(lib.elem p cfg.detectionPlugins)) cfg.plugins;
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

in
{
  config = lib.mkIf (cfg.enable && isClient) {
    warnings = nonDetectionWarnings;

    mares.automation.scrypted.provisionedPlugins = detectionPkgs;

    systemd.services.scrypted.environment = {
      SCRYPTED_CLUSTER_MODE = "client";
      SCRYPTED_CLUSTER_SERVER = cfg.cluster.serverAddr;
      SCRYPTED_CLUSTER_WORKER_NAME = cfg.cluster.workerName;
      SCRYPTED_CLUSTER_LABELS = lib.concatStringsSep "," labels;
    };
  };
}
