{
  lib,
  callPackage,
  newScope,
}:
let
  mkScryptedPlugin = callPackage ../mk-scrypted-plugin.nix { };
in
lib.packagesFromDirectoryRecursive {
  callPackage = newScope { inherit mkScryptedPlugin; };
  directory = ./.;
}
