{
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkEnableOption mkOption types;
in
{
  options.mares.shell.atuin = {
    enable = mkEnableOption "Atuin shell history client";

    package = mkOption {
      type = types.package;
      default = pkgs.atuin;
      description = "The atuin package to use.";
    };

    username = mkOption {
      type = types.str;
      description = "Atuin service username.";
    };

    passwordPath = mkOption {
      type = types.path;
      description = "Path to the sops-nix secret containing the atuin password.";
    };

    keyPath = mkOption {
      type = types.path;
      description = "Path to the sops-nix secret containing the atuin key.";
    };

    owner = mkOption {
      type = types.str;
      description = "The local system user to configure atuin for.";
      default = "root";
    };

    settings = mkOption {
      type = with types; attrsOf anything;
      description = "Atuin client settings.";
      example = ''
        {
          sync_address = "https://atuin.example.com";
          key_path = "/home/user/.atuin/key";
          auto_sync = true;
          dialect = "uk";
          style = "auto";
        }
      '';
    };
  };
}
