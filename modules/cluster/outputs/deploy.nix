{
  config,
  lib,
  inputs,
  ...
}:
let
  managedNodes = lib.filterAttrs (_: node: node.managed or false) config.cluster.nodes;

  mkDeployNode = name: nodeCfg: {

    hostname = nodeCfg.host;

    profiles.system = {
      sshUser = nodeCfg.user;
      user = "root";
      interactiveSudo = true;
      remoteBuild = false;
      fastConnection = true;
      path =
        inputs.deploy-rs.lib.${nodeCfg.system}.activate.nixos
          config.flake.nixosConfigurations.${name};
    };
  };
in
{

  config.flake = {
    deploy.nodes = lib.mapAttrs mkDeployNode managedNodes;
  };
}
