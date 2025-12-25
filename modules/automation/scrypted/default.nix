{ ... }:
{
  imports = [
    ./common.nix
    ./server.nix
    ./client-openvino.nix
    ../../services/scrypted.nix
    ../../users/scrypted.nix
  ];
}
