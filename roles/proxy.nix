{
  ...
}:

{
  imports = [
    ../modules/security/acme.nix
    ../modules/networking/proxy-nginx.nix
  ];

  sops-vault.items = [ "easydns" ];

  mares.networking = {
    acme.enable = true;
    proxy-nginx.enable = true;
  };
}
