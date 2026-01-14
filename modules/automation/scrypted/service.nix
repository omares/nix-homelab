{
  config,
  lib,
  ...
}:
let
  cfg = config.mares.automation.scrypted;
in
{
  config = lib.mkIf cfg.enable {
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
      };

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

        EnvironmentFile = cfg.environmentFiles;
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
