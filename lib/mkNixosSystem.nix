{
  nixpkgs,
  config,
  homelabLib,
  sops-nix,
  nix-sops-vault,
}:
name: nodeCfg:
nixpkgs.lib.nixosSystem {
  inherit (nodeCfg) system;

  deployment = {
    targetUser = nodeCfg.user;
    targetHost = nodeCfg.host;
    tags = [ name ];
  };

  specialArgs = {
    inherit nixpkgs homelabLib;
    modulesPath = toString nixpkgs + "/nixos/modules";
  };

  modules = [
    {
      networking.hostName = name;
    }
    sops-nix.nixosModules.sops
    # nix-sops-vault.nixosModules.sops-vault
    config.nixosModules.role-default
  ] ++ nodeCfg.roles;

  extraModules = [ inputs.colmena.nixosModules.deploymentOptions ];
}
