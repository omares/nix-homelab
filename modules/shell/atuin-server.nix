{
  config,
  lib,
  nodeCfg,
  mares,
  ...
}:
let
  cfg = config.mares.shell.atuin-server;
  dbAddress = "${mares.infrastructure.nodes.db-01.dns.fqdn}:${toString config.services.pgbouncer.settings.pgbouncer.listen_port}";
in
{
  options.mares.shell.atuin-server = {
    enable = lib.mkEnableOption "Enable atuin server";
  };

  config = lib.mkIf cfg.enable {

    sops.templates."atuin-env" = {
      content = ''
        ATUIN_DB_URI="postgresql://atuin:${config.sops.placeholder.pgsql-atuin_password}@${dbAddress}/atuin"
      '';
      restartUnits = [ "atuin.service" ];
    };

    systemd.services.atuin = {
      serviceConfig = {
        EnvironmentFile = config.sops.templates."atuin-env".path;
      };
    };

    services.atuin = {
      enable = true;
      openRegistration = true;
      openFirewall = true;
      host = nodeCfg.host;
      database = {
        createLocally = false;
      };
    };
  };
}
