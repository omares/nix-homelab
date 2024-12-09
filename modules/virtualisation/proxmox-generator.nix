{
  homelabLib,
  nixos-generators,
  system,
  nixpkgs,
  extraModules ? [ ],
}:
nixos-generators.nixosGenerate {
  inherit system;
  modules = [
    ../_all.nix
    { nix.registry.nixpkgs.flake = nixpkgs; }
    ./proxmox-default.nix
  ] ++ extraModules;

  specialArgs = {
    inherit homelabLib;
  };

  format = "proxmox";
}
