{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.mares.networking.tailscale;
in
{
  options.mares.networking.tailscale = {
    enable = lib.mkEnableOption "Tailscale VPN client";

    authKeyFile = lib.mkOption {
      type = lib.types.path;
      description = "Path to Tailscale auth key file (via sops)";
    };

    useAsExitNode = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Allow this node to be an exit node (route all internet traffic)";
    };

    advertiseRoutes = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Subnets to advertise via Tailscale (e.g., [\"10.10.22.0/24\", \"192.168.20.0/24\"])";
    };

    acceptRoutes = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Accept routes advertised by other Tailscale nodes";
    };

    useTailscaleSSH = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable Tailscale SSH (authenticate via Tailscale identity)";
    };

    extraUpFlags = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Additional flags for 'tailscale up' command";
    };
  };
}
