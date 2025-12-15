{
  lib,
  config,
  ...
}:
{
  flake.deployGroups =
    let
      nodes = config.mares.infrastructure.nodes;
      managedNodes = lib.filterAttrs (_: cfg: cfg.managed or true) nodes;
      perNode = lib.mapAttrsToList (
        name: cfg: lib.genAttrs (cfg.deployGroups or [ ]) (_: [ name ])
      ) managedNodes;
    in
    lib.zipAttrsWith (_: lib.flatten) perNode;
}
