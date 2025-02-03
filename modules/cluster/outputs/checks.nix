{
  config,
  inputs,
  ...
}:
{

  config.flake = {
    checks = builtins.mapAttrs (
      system: deployLib: deployLib.deployChecks config.flake.deploy
    ) inputs.deploy-rs.lib;
  };
}
