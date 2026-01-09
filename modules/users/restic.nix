{ lib, config, ... }:
let
  cfg = config.mares.users.restic;
in
{
  options.mares.users.restic = {
    enable = lib.mkEnableOption "Restic backup user";
  };

  config = lib.mkIf cfg.enable {
    users.users.restic = {
      group = "restic";
      isSystemUser = true;
    };

    users.groups.restic = { };
  };
}
