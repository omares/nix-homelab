{
  perSystem =
    {
      pkgs,
      ...
    }:
    {
      devShells.default = pkgs.mkShell {
        packages = [
          pkgs.deploy-rs
          pkgs.compose2nix
        ];
      };
    };
}
