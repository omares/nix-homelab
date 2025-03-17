{ ... }:
{
  imports = [
    ../modules/networking/resolved.nix
    ../modules/networking/adguard-home.nix
  ];

  sops-vault.items = [ "adguard-home" ];

  mares.networking = {
    adguard-home.enable = true;
  };
}
