{
  inputs,
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config.mares.starr;
in
{
  config = lib.mkIf (cfg.enable && cfg.jellyseerr.enable) {

    sops.templates."jellyseerr-config.env" = {
      content = ''
        DB_TYPE="postgres"
        DB_HOST="${toString cfg.postgres.host}"
        DB_PORT="${toString cfg.postgres.port}"
        DB_USER="jellyseerr"
        DB_PASS="${config.sops.placeholder.pgsql-jellyseerr_password}"
        DB_NAME="jellyseerr"
        DB_LOG_QUERIES="false"
      '';

      owner = cfg.jellyseerr.user;
      group = cfg.group;

      restartUnits = [ "jellyseerr.service" ];
    };

    # In case a version update is required
    # nixpkgs.overlays = [
    #   (final: prev: {
    #     jellyseerr = inputs.nixpkgs.legacyPackages.${prev.system}.jellyseerr.overrideAttrs (oldAttrs: {
    #       version = "2.2.3";
    #       src = oldAttrs.src // {
    #         hash = "sha256-JkbmCyunaMngAKUNLQHxfa1pktXxTjeL6ngvIgiAsGo=";
    #       };
    #       pnpmDeps = oldAttrs.pnpmDeps // {
    #         hash = "sha256-1r2+aeRb6zdpqqimufibVRjeAdvwHL0GiQSu5pHBh+U=";
    #       };
    #     });
    #   })
    # ];

    services.jellyseerr = {
      enable = true;
      openFirewall = true;
      package = inputs.nixpkgs-master.legacyPackages.${pkgs.system}.jellyseerr;
    };

    systemd.services.jellyseerr = {
      serviceConfig = {
        DynamicUser = lib.mkForce false;
        User = lib.mkDefault cfg.jellyseerr.user;
        Group = lib.mkDefault cfg.group;
        EnvironmentFile = [ config.sops.templates."jellyseerr-config.env".path ];
      };
    };
  };
}
