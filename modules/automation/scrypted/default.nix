{ ... }:
{
  imports = [
    ./options.nix
    ./service.nix
    ./server.nix
    ./client-openvino.nix
    ../../users/scrypted.nix
  ];
}
