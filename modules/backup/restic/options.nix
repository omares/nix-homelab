{ lib, ... }:
{
  options.mares.backup.restic = {
    enable = lib.mkEnableOption "Restic backup to TrueNAS";

    sshKeyFile = lib.mkOption {
      type = lib.types.path;
      description = "Path to SSH private key for TrueNAS SFTP authentication.";
    };

    jobs = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule {
          options = {
            repoPath = lib.mkOption {
              type = lib.types.str;
              description = "Repository path on TrueNAS relative to backup root.";
              example = "hass";
            };

            passwordFile = lib.mkOption {
              type = lib.types.path;
              description = "Path to file containing repository encryption key.";
            };

            paths = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              description = "Paths to back up.";
              example = [ "/var/lib/hass/.storage" ];
            };

            exclude = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              default = [ ];
              description = "Patterns to exclude from backup.";
            };

            timerConfig = lib.mkOption {
              type = lib.types.attrs;
              default = {
                OnCalendar = "*-*-* 03:00:00";
              };
              description = "Systemd timer configuration.";
            };

            pruneOpts = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              default = [
                "--keep-daily 7"
                "--keep-weekly 4"
                "--keep-monthly 12"
                "--keep-yearly 2"
              ];
              description = "Retention policy options for restic forget.";
            };

            extraBackupArgs = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              default = [ ];
              description = "Extra arguments to pass to restic backup.";
            };

            backupPrepareCommand = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
              description = "Command to run before backup.";
            };

            backupCleanupCommand = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
              description = "Command to run after backup.";
            };
          };
        }
      );
      default = { };
      description = "Backup jobs to configure.";
    };
  };
}
