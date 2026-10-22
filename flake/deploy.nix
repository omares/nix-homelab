{
  config,
  lib,
  inputs,
  ...
}:
let
  managedNodes = lib.filterAttrs (_: node: node.managed or false) config.mares.infrastructure.nodes;

  mkDeployNode = name: nodeCfg: {

    hostname = nodeCfg.host;

    profiles.system = {
      sshUser = nodeCfg.user;
      user = "root";
      # Let targets substitute public paths from the binary cache instead of copying everything over SSH
      fastConnection = false;
      path =
        inputs.deploy-rs.lib.${nodeCfg.system}.activate.nixos
          config.flake.nixosConfigurations.${name};
    };
  };
in
{

  flake = {
    deploy.nodes = lib.mapAttrs mkDeployNode managedNodes;
  };
}
