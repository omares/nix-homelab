{
  lib,
  config,
  ...
}:
{
  flake.tags =
    let
      nodes = config.mares.infrastructure.nodes;
      managedNodes = lib.filterAttrs (_: cfg: cfg.managed or true) nodes;
      perNode = lib.mapAttrsToList (
        name: cfg: lib.genAttrs (cfg.tags or [ ]) (_: [ name ])
      ) managedNodes;
    in
    lib.zipAttrsWith (_: lib.flatten) perNode;
}
