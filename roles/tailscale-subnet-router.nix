{
  config,
  ...
}:
{
  imports = [ ../modules/networking/tailscale ];

  sops-vault.items = [ "tailscale" ];

  mares.networking.tailscale = {
    enable = true;
    authKeyFile = config.sops.secrets.tailscale-authkey.path;

    # Advertise all internal networks
    advertiseRoutes = [
      "10.10.22.0/24" # vm
      "192.168.20.0/24" # iot
      "192.168.30.0/24" # not
    ];
  };

  networking.interfaces = {
    enp6s19.useDHCP = true; # vm
    enp6s20.useDHCP = true; # not
  };

  # Trust internal interfaces for forwarding traffic between networks
  networking.firewall.trustedInterfaces = [
    "eth0" # iot
    "enp6s19" # vm
    "enp6s20" # not
  ];
}
