{ ... }:
{
  imports = [
    ./common.nix
    ./server.nix
    ./client-tensorflow.nix
    ./client-openvino.nix
    ../../services/scrypted.nix
    ../../users/scrypted.nix
  ];
}
