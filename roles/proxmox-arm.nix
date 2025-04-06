{
  lib,
  ...
}:

{
  imports = [
    ../modules/users/builder-root.nix
  ];

  nix.settings = {
    substituters = [
      "https://cache.nixos.org"
      "https://nix-community.cachix.org"
    ];
    trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };

  mares.vm-profile.template = lib.mkDefault "proxmox-arm";
}
