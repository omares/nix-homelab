{
  inputs,
  ...
}:
{
  imports = [
    inputs.sops-nix.nixosModules.sops
    inputs.nix-sops-vault.nixosModules.sops-vault
    ../../users/starr.nix
    ../../services/starr/sonarr.nix
  ];

  sops-vault.items = [
    "starr"
    "pgsql"
  ];
}
