{
  sops-nix,
  nix-sops-vault,
  ...
}:
{
  imports = [
    # sops-nix.nixosModules.sops
    # nix-sops-vault.nixosModules.sops-vault
  ];
}
