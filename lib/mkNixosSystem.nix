{
  nixpkgs,
  config,
  homelabLib,
}:
name: nodeCfg:
nixpkgs.lib.nixosSystem {
  inherit (nodeCfg) system;

  specialArgs = {
    inherit nixpkgs homelabLib;
    modulesPath = toString nixpkgs + "/nixos/modules";
  };

  modules = [
    {
      networking.hostName = name;
    }
    config.nixosModules.role-default
  ] ++ nodeCfg.roles;
}
