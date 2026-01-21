{ ... }:
{
  imports = [
    ./options.nix
    ./service.nix
    ./server.nix
    ./client.nix
    ../../users/scrypted.nix
  ];
}
