{
  inputs,
  nodeCfg,
  mares,
  config,
  ...
}:
let
  dbAddress = "${mares.infrastructure.nodes.db-01.host}:${toString config.services.pgbouncer.settings.pgbouncer.listen_port}";
in
{
  imports = [
    inputs.sops-nix.nixosModules.sops
    inputs.nix-sops-vault.nixosModules.sops-vault
  ];

  sops-vault.items = [ "pgsql" ];

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
}
