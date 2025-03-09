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
          pkgs.nixfmt-rfc-style
          pkgs.compose2nix
        ];
      };
    };
}
