{
  config,
  lib,
  ...
}:
let
  cfg = config.mares.automation.evcc;
in
{
  config = lib.mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = lib.mkIf cfg.openFirewall [
      7070
      8887
    ];

    services.evcc = {
      enable = true;
      environmentFile = cfg.secretsFile;
      settings = cfg.settings;
    };
  };
}
