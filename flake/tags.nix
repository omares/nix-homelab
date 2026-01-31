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
  flake = {
    nodes = lib.attrNames managedNodes;

    tags =
      let
        perNode = lib.mapAttrsToList (name: cfg: lib.genAttrs (cfg.tags or [ ]) (_: [ name ])) managedNodes;
      in
      lib.zipAttrsWith (_: lib.flatten) perNode;
  };
}
