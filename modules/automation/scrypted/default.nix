{ inputs, ... }:
{
  imports = [
    inputs.sops-nix.nixosModules.sops
    inputs.nix-sops-vault.nixosModules.sops-vault
    ./common.nix
    ./server.nix
    ./client-tensorflow.nix
    ./client-openvino.nix
    ../../services/scrypted.nix
    ../../users/scrypted.nix
    ../../hardware/intel-graphics.nix
    ../../storage/truenas.nix
  ];
}
