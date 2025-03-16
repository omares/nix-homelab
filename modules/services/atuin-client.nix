# atuin-client.nix
{
  config,
  lib,
  pkgs,
  ...
}:

let
  tomlFormat = pkgs.formats.toml { };
  cfg = config.mares.services.atuin-client;
  userInfo = config.users.users.${cfg.owner};
  configDir = "${userInfo.home}/.config/atuin";
in
{
  options.mares.services.atuin-client = {
    enable = lib.mkEnableOption "Atuin shell history client";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.atuin;
      description = "The atuin package to use.";
    };

    username = lib.mkOption {
      type = lib.types.str;
      description = "Atuin service username.";
    };

    passwordPath = lib.mkOption {
      type = lib.types.path;
      description = "Path to the sops-nix secret containing the atuin password.";
    };

    keyPath = lib.mkOption {
      type = lib.types.path;
      description = "Path to the sops-nix secret containing the atuin key.";
    };

    owner = lib.mkOption {
      type = lib.types.str;
      description = "The local system user to configure atuin for.";
      default = "root";
    };

    settings = lib.mkOption {
      type = with lib.types; attrsOf anything;
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

  config = lib.mkIf cfg.enable {
    systemd.tmpfiles.settings.atuin-client = {
      "${configDir}" = {
        d = {
          mode = "0700";
          user = cfg.owner;
          group = userInfo.group;
        };
      };
    };

    sops.templates."atuin-config-${cfg.owner}.toml" = {
      owner = cfg.owner;
      group = userInfo.group;
      mode = "0600";
      file = tomlFormat.generate "atuin-config.toml" cfg.settings;
      path = "${configDir}/config.toml";
    };

    environment.systemPackages = [ cfg.package ];

    systemd.user.services.atuin-login = {
      description = "Atuin login service";
      wantedBy = [ "default.target" ];
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];

      unitConfig = {
        ConditionPathExists = "!${configDir}/session";
      };

      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };

      script = ''
        eval "$(${lib.getExe cfg.package} init zsh)" || true
        ${lib.getExe cfg.package} login -u ${cfg.username} -p "$(cat ${cfg.passwordPath})"  -k "$(cat ${cfg.keyPath})" || true
        ${lib.getExe cfg.package} sync
      '';
    };

    programs.zsh.interactiveShellInit = ''
      eval "$(${lib.getExe cfg.package} init zsh)"
    '';
  };
}
