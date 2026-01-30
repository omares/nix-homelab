{
  config,
  lib,
  pkgs,
  ...
}:
let
  tomlFormat = pkgs.formats.toml { };
  cfg = config.mares.shell.atuin;
  userInfo = config.users.users.${cfg.owner};
  configDir = "${userInfo.home}/.config/atuin";
in
{
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
