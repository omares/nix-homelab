{
  nixpkgs,
  ...
}:
{

  flake = {
    lib = import ../lib {
      inherit (nixpkgs) lib;
    };
  };
}
