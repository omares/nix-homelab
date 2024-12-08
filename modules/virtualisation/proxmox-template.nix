{
  homelabLib,
  nixos-generators,
  system,
  nixpkgs,
  extraModules ? [ ],
}:
let
  proxmoxConfig = homelabLib.getProxmoxTemplate system;
in
nixos-generators.nixosGenerate {
  inherit system;
  modules = [
    ../_all.nix
    { nix.registry.nixpkgs.flake = nixpkgs; }
    proxmoxConfig
  ] ++ extraModules;
  format = "proxmox";
}
