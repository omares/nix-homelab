{
  inputs,
  config,
  lib,
  ...
}:

let
  cfg = config.cluster.services.starr;
in
{
  disabledModules = [ "services/misc/jellyseerr.nix" ];
  imports = [ "${inputs.nixpkgs-master}/nixos/modules/services/misc/jellyseerr.nix" ];

  config = lib.mkIf (cfg.enable && cfg.jellyseerr.enable) {

    services.jellyseerr = {
      enable = true;
      openFirewall = true;
    };

    systemd.services.jellyseerr = {
      serviceConfig = {
        DynamicUser = lib.mkForce false;
        User = lib.mkDefault cfg.jellyseerr.user;
        Group = lib.mkDefault cfg.group;
      };
    };
  };
}
