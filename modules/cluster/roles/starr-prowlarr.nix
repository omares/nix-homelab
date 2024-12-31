{
  inputs,
  config,
  lib,
  ...
}:
{
  imports = [
    inputs.sops-nix.nixosModules.sops
    inputs.nix-sops-vault.nixosModules.sops-vault
    ../../services/prowlarr.nix
  ];

  sops-vault.items = [
    "starr"
    "pgsql"
  ];
}
