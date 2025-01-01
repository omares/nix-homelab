{
  inputs,
  ...
}:
{
  imports = [
    inputs.sops-nix.nixosModules.sops
    inputs.nix-sops-vault.nixosModules.sops-vault
    ../../users/starr.nix
    ../../services/starr/radarr.nix
  ];

  sops-vault.items = [
    "starr"
    "pgsql"
  ];
}
