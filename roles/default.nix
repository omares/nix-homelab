{
  ...
}:

{
  imports = [
    ../modules/cluster
    ../modules/virtualisation/vm-profile.nix
    ../modules/users/ids.nix
    ../modules/editors
    ../modules/environment
    ../modules/networking
    ../modules/nix
    ../modules/security
    ../modules/shell
    ../modules/system
    ../modules/users
  ];

  # On the first boot, cloud-init manages the network setup to retrieve a proper DHCP address.
  # After applying any role (which always includes this default) to the node,
  # cloud-init should be disabled as the node is now fully managed by our Nix code base.
  mares.proxmox-enhanced.cloudInit.enable = false;
  services.cloud-init.enable = false;
}
