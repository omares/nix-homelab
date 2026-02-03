# Lovelace Dashboard Configuration
#
# Manages YAML-based dashboards alongside the default storage-mode dashboard.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.mares.home-assistant;
  format = pkgs.formats.yaml { };

  maresHomeDashboard = import ./dashboards/mares-home.nix { inherit format; };
in
{
  config = lib.mkIf cfg.enable {
    services.home-assistant.config.lovelace = {
      mode = "storage";
      dashboards = {
        mares-energy = {
          mode = "yaml";
          title = "Mares Energy";
          icon = "mdi:home-lightning-bolt";
          filename = "${maresHomeDashboard}";
          show_in_sidebar = true;
        };
      };
    };
  };
}
