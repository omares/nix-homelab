{
  imports = [
    ./scrypted.nix
    ./client-tensorflow.nix
    ../../services/scrypted.nix
    ../../users/scrypted.nix
    ../../hardware/intel-graphics.nix
    ../../storage/truenas.nix
  ];
}
