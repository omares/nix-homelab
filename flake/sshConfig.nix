{
  lib,
  config,
  ...
}:
let
  nodes = config.mares.infrastructure.nodes;
  managedNodes = lib.filterAttrs (_: cfg: cfg.managed or true) nodes;
in
{
  flake.sshConfig = lib.mapAttrs (name: cfg: {
    hostname = cfg.host;
    user = "omares";
  }) managedNodes;
}
