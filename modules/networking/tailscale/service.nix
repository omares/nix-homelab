{
  config,
  lib,
  ...
}:
let
  cfg = config.mares.networking.tailscale;
in
lib.mkIf cfg.enable {
  services.tailscale = {
    enable = true;
    authKeyFile = cfg.authKeyFile;
    # "server" enables IP forwarding, "client" enables loose reverse path filtering
    # Use "server" for subnet router or exit node, "client" for accepting routes
    useRoutingFeatures =
      if (cfg.advertiseRoutes != [ ] || cfg.useAsExitNode) then
        "server"
      else if cfg.acceptRoutes then
        "client"
      else
        "none";
    extraUpFlags =
      cfg.extraUpFlags
      ++ (lib.optional cfg.useTailscaleSSH "--ssh")
      ++ (lib.optionals (cfg.advertiseRoutes != [ ]) [
        "--advertise-routes"
        (lib.concatStringsSep "," cfg.advertiseRoutes)
      ])
      ++ (lib.optional cfg.acceptRoutes "--accept-routes")
      ++ (lib.optional cfg.useAsExitNode "--advertise-exit-node");
  };

  # Trust tailscale0 interface in firewall
  networking.firewall.trustedInterfaces = [ "tailscale0" ];
}
