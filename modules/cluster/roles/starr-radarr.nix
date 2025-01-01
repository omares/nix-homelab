{
  inputs,
  ...
}:
{
  imports = [
    inputs.sops-nix.nixosModules.sops
    inputs.nix-sops-vault.nixosModules.sops-vault
    ../../users/starr.nix
    ../../services/radarr.nix
  ];

  sops-vault.items = [
    "starr"
    "pgsql"
  ];
}
