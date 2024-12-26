{
  pkgs,
  lib,
  user,
  ...
}:
{

  nix.package = pkgs.nixVersions.stable;

  nixpkgs.config.allowUnfree = true;

  nix.settings = {
    experimental-features = "nix-command flakes";
    # enable auto-cleanup
    auto-optimise-store = true;
    # set max-jobs
    max-jobs = lib.mkDefault 8;
    # enable ccache (local compilation)
    # extra-sandbox-paths = [ config.programs.ccache.cacheDir ];
    trusted-users = [
      "root"
      "@wheel"
    ];
    # trusted-public-keys = [ ];

    # substituers will be appended to the default substituters when fetching packages
    extra-substituters = [ ];
    extra-trusted-public-keys = [ ];
  };
}
