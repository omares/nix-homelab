{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.cluster.services.recyclarr;
in
{
  options.cluster.services.recyclarr = {
    enable = mkEnableOption "recyclarr service";

    package = mkOption {
      type = types.package;
      default = pkgs.recyclarr;
      defaultText = literalExpression "pkgs.recyclarr";
      description = "The recyclarr package to use.";
    };

    command = mkOption {
      type = types.str;
      default = "sync";
      description = "The recyclarr command to run (e.g., sync).";
    };

    configFile = mkOption {
      type = types.either types.path types.str;
      description = "Path to the recyclarr configuration file.";
    };

    workingDir = mkOption {
      type = types.path;
      default = "/var/lib/recyclarr";
      description = "Working directory for recyclarr.";
    };

    schedule = mkOption {
      type = types.str;
      default = "*-*-* 04:00:00"; # Every day at 4 AM
      description = "When to run recyclarr in systemd calendar format.";
    };

    user = mkOption {
      type = types.str;
      default = "recyclarr";
      description = "User account under which recyclarr runs.";
    };

    group = mkOption {
      type = types.str;
      default = "recyclarr";
      description = "Group under which recyclarr runs.";
    };
  };

  config = mkIf cfg.enable {

    users.users = mkIf (cfg.user == "recyclarr") {
      recyclarr = {
        description = "recyclarr user";
        home = cfg.workingDir;
        group = cfg.group;
        uid = config.ids.uids.recyclarr;
      };
    };

    users.groups = mkIf (cfg.group == "starr") {
      starr.gid = config.ids.gids.starr;
    };

    systemd.tmpfiles.rules = [
      "d ${cfg.workingDir} 0750 ${cfg.user} ${cfg.group} -"
    ];

    systemd.services.recyclarr = {
      description = "Recyclarr Service";
      after = [ "network.target" ];
      path = [ cfg.package ];

      serviceConfig = {
        Type = "oneshot";
        User = cfg.user;
        Group = cfg.group;
        WorkingDirectory = cfg.workingDir;
        ExecStart = "${lib.getExe cfg.package} ${cfg.command} --app-data ${cfg.workingDir} --config ${cfg.configFile}";
      };
    };

    systemd.timers.recyclarr = {
      description = "Recyclarr Timer";
      wantedBy = [ "timers.target" ];

      timerConfig = {
        OnCalendar = cfg.schedule;
        Persistent = true;
        RandomizedDelaySec = "5m";
        Unit = "recyclarr.service";
      };
    };
  };
}
