{
  inputs,
  ...
}:
{
  imports = [
    inputs.sops-nix.nixosModules.sops
    inputs.nix-sops-vault.nixosModules.sops-vault
    ../../users/starr.nix
    ../../users/prowlarr.nix
    ../../services/starr/prowlarr.nix
  ];

  sops-vault.items = [
    "starr"
    "pgsql"
  ];
}
