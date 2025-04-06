{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.mares.automation.scrypted;
  isServer = cfg.role == "server";
in
{
  config = lib.mkIf (cfg.enable && isServer) {

    mares.services.scrypted = {
      enable = true;
      package = pkgs.callPackage ../../../packages/scrypted.nix { };
      openFirewall = true;
      extraEnvironment = {
        SCRYPTED_CLUSTER_LABELS = "storage";
        SCRYPTED_CLUSTER_MODE = "server";
        SCRYPTED_CLUSTER_ADDRESS = cfg.serverHost;
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
    };
  };
}
