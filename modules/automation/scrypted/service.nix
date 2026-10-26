{
  config,
  lib,
  ...
}:
let
  cfg = config.mares.automation.scrypted;

  # "a/b/c" -> [ "a" "a/b" ]
  parentDirs =
    target:
    let
      parts = lib.init (lib.splitString "/" target);
    in
    lib.genList (i: lib.concatStringsSep "/" (lib.take (i + 1) parts)) (lib.length parts);

  # Symlinks relative to the plugin volume, e.g. pre-provisioned Python envs, models or native addons
  mkProvisionRules =
    pkg:
    let
      pluginPath = "${cfg.installPath}/volume/plugins/${pkg.pluginName}";
      symlinks = pkg.provision.symlinks or [ ];
      # tmpfiles would create missing parents of symlinks as root
      dirs = lib.unique (lib.concatMap (link: parentDirs link.target) symlinks);
    in
    lib.optionals (pkg ? provision) (
      [ "d ${pluginPath} 0755 ${cfg.user} ${cfg.group} -" ]
      ++ map (dir: "d ${pluginPath}/${dir} 0755 ${cfg.user} ${cfg.group} -") dirs
      ++ map (link: "L+ ${pluginPath}/${link.target} - - - - ${link.path}") symlinks
    );
in
{
  config = lib.mkIf cfg.enable {
    warnings = lib.concatMap (pkg: pkg.provision.warnings or [ ]) cfg.provisionedPlugins;

    systemd.tmpfiles.rules = lib.concatMap mkProvisionRules cfg.provisionedPlugins;

    # Contains SCRYPTED_CLUSTER_SECRET for cluster authentication
    sops.secrets.scrypted-environment = {
      owner = cfg.user;
      group = cfg.group;
    };

    systemd.services.scrypted = {
      description = "Scrypted home automation server";
      after = [
        "network.target"
        "sops-nix.service"
      ];
      wants = [ "sops-nix.service" ];
      wantedBy = [ "multi-user.target" ];

      environment = {
        SCRYPTED_CAN_RESTART = "true";
        SCRYPTED_INSTALL_PATH = cfg.installPath;
        SCRYPTED_VOLUME = "${cfg.installPath}/volume";
        NODE_OPTIONS = "--dns-result-order=ipv4first";
      }
      // lib.mergeAttrsList (map (pkg: pkg.provision.environment or { }) cfg.provisionedPlugins);

      serviceConfig = {
        ExecStart = "${lib.getExe cfg.package}";
        Restart = "always";
        RestartSec = "3";

        User = cfg.user;
        Group = cfg.group;

        StateDirectory = "scrypted";
        StateDirectoryMode = "0750";

        ProtectSystem = "strict";
        ProtectHome = true;
        WorkingDirectory = cfg.installPath;
        ReadWritePaths = [ cfg.installPath ];
        PrivateDevices = false;
        PrivateTmp = true;
        NoNewPrivileges = true;
        RestrictRealtime = true;

        RestrictAddressFamilies = [
          "AF_INET"
          "AF_INET6"
          "AF_NETLINK"
        ];

        EnvironmentFile = cfg.environmentFiles ++ [
          config.sops.secrets.scrypted-environment.path
        ];
      };
    };

    users.users = lib.mkIf (cfg.user == "scrypted") {
      ${cfg.user} = {
        uid = config.ids.uids.scrypted;
        isSystemUser = true;
        group = cfg.group;
        home = cfg.installPath;
        createHome = true;
        description = "Scrypted service user";
      };
    };

    users.groups = lib.mkIf (cfg.group == "scrypted") {
      ${cfg.group}.gid = config.ids.gids.scrypted;
    };

    networking.firewall = lib.mkIf cfg.openFirewall {
      allowedTCPPorts = [
        80
        443
        10443
        10556
        11080
      ];

      # WebRTC TCP ports
      allowedTCPPortRanges = [
        {
          from = 30000;
          to = 60999;
        }
      ];

      # WebRTC UDP ports
      allowedUDPPortRanges = [
        {
          from = 30000;
          to = 60999;
        }
      ];

      # DoorBird event notifications (UDP broadcast)
      allowedUDPPorts = [ 6524 ];
    };
  };
}
