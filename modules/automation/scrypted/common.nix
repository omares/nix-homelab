{
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

  config = lib.mkIf cfg.enable {
    networking.firewall.enable = lib.mkForce false;
    networking.firewall.allowedTCPPortRanges = [
      {
        from = 32768;
        to = 60999;
      }
    ];

    sops.secrets.scrypted-environment = {
      owner = config.services.scrypted.user;
      group = config.services.scrypted.group;
    };

    sops-vault.items = [ "scrypted" ];
  };
}
