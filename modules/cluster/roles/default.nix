{
  ...
}:

{
  imports = [
    ../../virtualisation/vm-profile.nix
    ../../_all.nix
  ];

  # On the first boot, cloud-init manages the network setup to retrieve a proper DHCP address.
  # After applying any role (which always includes this default) to the node,
  # cloud-init should be disabled as the node is now fully managed by our Nix code base.
  proxmox-enhanced.cloudInit.enable = false;
  services.cloud-init.enable = false;
}
