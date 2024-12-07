{
  lib,
  nixos-generators,
  system,
  nixpkgs,
  extraModules ? [ ],
}:
let
  proxmoxConfig = lib.getProxmoxTemplate system;
in
#assert builtins.trace "Using proxmox config: ${toString proxmoxConfig}" true;
#assert lib.traceVal proxmoxConfig != null;
nixos-generators.nixosGenerate {
  inherit system;
  modules = [
    ../_all.nix
    { nix.registry.nixpkgs.flake = nixpkgs; }
    proxmoxConfig
  ] ++ extraModules;
  format = "proxmox";
}
