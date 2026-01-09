{ lib, ... }:
{
  options.mares.automation.evcc = {
    enable = lib.mkEnableOption "evcc";
    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether to open the firewall for evcc UI and OCPP.";
    };
    secretsFile = lib.mkOption {
      type = lib.types.path;
      description = "Path to the environment file containing secrets for envsubst.";
    };
    settings = lib.mkOption {
      type = lib.types.attrs;
      default = { };
      description = "Structured evcc settings (YAML).";
    };
  };
}
