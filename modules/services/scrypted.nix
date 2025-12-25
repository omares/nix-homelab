{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.mares.services.scrypted;
in
{
  options.mares.services.scrypted = {
    enable = lib.mkEnableOption "Scrypted home automation server";

    package = lib.mkPackageOption pkgs "scrypted" { };

    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Open ports 11080 and 10443 in the firewall";
    };

    installPath = lib.mkOption {
      type = lib.types.path;
      default = "/var/lib/scrypted";
      description = "Directory where scrypted data will be stored";
    };

    user = lib.mkOption {
      type = lib.types.str;
      default = "scrypted";
      description = "User account under which scrypted runs";
    };

    group = lib.mkOption {
      type = lib.types.str;
      default = "scrypted";
      description = "Group account under which scrypted runs";
    };

    environmentFiles = lib.mkOption {
      type = lib.types.listOf lib.types.path;
      default = [ ];
      description = "Environment files to pass to service.";
      example = [
        /path/to/.env
        /path/to/.env.secret
      ];
    };

    extraEnvironment = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
      description = "Additional environment variables for scrypted";
      example = {
        SCRYPTED_NVR_VOLUME = "/var/lib/scrypted/nvr";
        SCRYPTED_SECURE_PORT = 443;
        SCRYPTED_INSECURE_PORT = 8080;
      };
    };
  };

  config = lib.mkIf cfg.enable {

    systemd.services.scrypted = {
      description = "Scrypted home automation server";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      environment = lib.mkMerge [
        {
          SCRYPTED_CAN_RESTART = "true";
          SCRYPTED_INSTALL_PATH = cfg.installPath;
          SCRYPTED_VOLUME = "${cfg.installPath}/volume";
          NODE_OPTIONS = "--dns-result-order=ipv4first";
        }
        cfg.extraEnvironment
      ];

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
        isSystemUser = true;
        group = cfg.group;
        home = cfg.installPath;
        createHome = true;
        description = "Scrypted service user";
      };
    };

    users.groups = lib.mkIf (cfg.group == "scrypted") { ${cfg.group} = { }; };

    networking.firewall = lib.mkIf cfg.openFirewall {
      allowedTCPPorts = [
        11080
        10443
      ];
    };
  };
}
