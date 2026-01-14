{
  lib,
  config,
  ...
}:
let
  cfg = config.mares.automation.scrypted;
in
{
  options.mares.automation.scrypted = {
    enable = lib.mkEnableOption "Enable scrypted";

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
      description = "Worker name used for client identifcation";
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
  };

  config = lib.mkIf cfg.enable {
    # networking.firewall.enable = lib.mkForce false;
    networking.firewall = {
      allowedTCPPorts = lib.mkAfter [
        80
        443
        10443
        10556
      ];

      # WebRTC TCP ports
      allowedTCPPortRanges = lib.mkAfter [
        {
          from = 30000;
          to = 60999;
        }
      ];

      # WebRTC UDP ports
      allowedUDPPortRanges = lib.mkAfter [
        {
          from = 30000;
          to = 60999;
        }
      ];

      # DoorBird event notifications (UDP broadcast)
      allowedUDPPorts = lib.mkAfter [
        6524
      ];
    };

    sops.secrets.scrypted-environment = {
      owner = config.mares.services.scrypted.user;
      group = config.mares.services.scrypted.group;
    };
  };
}
