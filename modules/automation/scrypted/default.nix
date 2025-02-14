{ inputs, ... }:
{
  imports = [
    inputs.sops-nix.nixosModules.sops
    inputs.nix-sops-vault.nixosModules.sops-vault
    ./scrypted.nix
    ./client-tensorflow.nix
    ../../services/scrypted.nix
    ../../users/scrypted.nix
    ../../hardware/intel-graphics.nix
    ../../storage/truenas.nix
  ];
}
