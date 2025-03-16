# This version allows multiple backup services to run, allows options to be passed to pg_dumpall,
# and includes the option to prune backups that exceed the specified limit.
# Based on https://github.com/NixOS/nixpkgs/blob/nixos-unstable/nixos/modules/services/backup/postgresql-backup.nix.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  postgresqlBackupService =
    instanceCfg: db: dumpCmd:
    let
      compressSuffixes = {
        "none" = "";
        "gzip" = ".gz";
        "zstd" = ".zstd";
      };
      compressSuffix = lib.getAttr instanceCfg.compression compressSuffixes;

      compressCmd = lib.getAttr instanceCfg.compression {
        "none" = "cat";
        "gzip" = "${pkgs.gzip}/bin/gzip -c -${toString instanceCfg.compressionLevel} --rsyncable";
        "zstd" = "${pkgs.zstd}/bin/zstd -c -${toString instanceCfg.compressionLevel} --rsyncable";
      };

      mkSqlPath = timestamp: "${instanceCfg.location}/${db}-${timestamp}.sql${compressSuffix}";
      inProgressFile = "${instanceCfg.location}/${db}.in-progress${compressSuffix}";
    in
    {
      enable = true;

      description = "Backup of ${db} database(s)";

      requires = [ "postgresql.service" ];

      path = [
        pkgs.coreutils
        config.services.postgresql.package
      ];

      script = ''
        set -e -o pipefail

        umask 0077 # ensure backup is only readable by postgres user

        timestamp=$(date +%Y%m%d-%H%M%S)
        ${dumpCmd} \
          | ${compressCmd} \
          > ${inProgressFile}

        mv ${inProgressFile} ${mkSqlPath "$timestamp"}

        # Keep only the last X dumps
        cd ${instanceCfg.location} && \
          ls -t ${db}-*.sql${compressSuffix} 2>/dev/null | \
          tail -n +$((${toString instanceCfg.keep} + 1)) | \
          xargs -r rm --
      '';

      serviceConfig = {
        Type = "oneshot";
        User = "postgres";
      };

      startAt = instanceCfg.startAt;
    };

  backupInstanceOpts =
    { name, config, ... }:
    {
      options = {
        enable = lib.mkEnableOption "PostgreSQL dumps for ${name}";

        startAt = lib.mkOption {
          default = "*-*-* 01:15:00";
          type = with lib.types; either (listOf str) str;
          description = ''
            This option defines (see `systemd.time` for format) when the
            databases should be dumped.
            The default is to update at 01:15 (at night) every day.
          '';
        };

        backupAll = lib.mkOption {
          default = false;
          defaultText = lib.literalExpression "databases == []";
          type = lib.types.bool;
          description = ''
            Backup all databases using pg_dumpall.
            This option is mutual exclusive to databases.
            The resulting backup dump will have the name all.sql.gz.
            This option is the default if no databases are specified.
          '';
        };

        databases = lib.mkOption {
          default = [ ];
          type = lib.types.listOf lib.types.str;
          description = ''
            List of database names to dump.
          '';
        };

        location = lib.mkOption {
          default = "/var/backup/postgresql/${name}";
          type = lib.types.path;
          description = ''
            Path of directory where the PostgreSQL database dumps will be placed.
          '';
        };

        keep = lib.mkOption {
          type = lib.types.int;
          default = 7;
          description = "Number of backups to keep per database";
        };

        pgdumpOptions = lib.mkOption {
          type = lib.types.separatedString " ";
          default = "-C";
          description = ''
            Command line options for pg_dump.
          '';
        };

        compression = lib.mkOption {
          type = lib.types.enum [
            "none"
            "gzip"
            "zstd"
          ];
          default = "gzip";
          description = ''
            The type of compression to use on the generated database dump.
          '';
        };

        compressionLevel = lib.mkOption {
          type = lib.types.ints.between 1 19;
          default = 6;
          description = ''
            The compression level used when compression is enabled.
            gzip accepts levels 1 to 9. zstd accepts levels 1 to 19.
          '';
        };
      };
    };

in
{
  options.mares.services.postgresql-backup = lib.mkOption {
    type = lib.types.attrsOf (lib.types.submodule backupInstanceOpts);
    default = { };
    description = "PostgreSQL backup instances configuration.";
  };

  config =
    let
      fullBackups = lib.filterAttrs (
        name: cfg: cfg.enable && cfg.backupAll
      ) config.mares.services.postgresql-backup;

      dbBackups = lib.filterAttrs (
        name: cfg: cfg.enable && !cfg.backupAll
      ) config.mares.services.postgresql-backup;

      fullBackupServices = lib.mapAttrs' (
        name: cfg:
        lib.nameValuePair "postgresqlBackup-${name}" (
          postgresqlBackupService cfg "all" "pg_dumpall ${cfg.pgdumpOptions}"
        )
      ) fullBackups;

      dbBackupServices = lib.concatMapAttrs (
        name: cfg:
        lib.listToAttrs (
          map (db: {
            name = "postgresqlBackup-${name}-${db}";
            value = postgresqlBackupService cfg db "pg_dump ${cfg.pgdumpOptions} ${db}";
          }) cfg.databases
        )
      ) dbBackups;
    in
    {
      assertions = lib.concatLists (
        lib.mapAttrsToList (name: cfg: [
          {
            assertion = cfg.backupAll -> cfg.databases == [ ];
            message = "backupAll cannot be used together with databases in instance ${name}";
          }
          {
            assertion =
              cfg.compression == "none"
              || (cfg.compression == "gzip" && cfg.compressionLevel >= 1 && cfg.compressionLevel <= 9)
              || (cfg.compression == "zstd" && cfg.compressionLevel >= 1 && cfg.compressionLevel <= 19);
            message = "compressionLevel must be set between 1 and 9 for gzip and 1 and 19 for zstd in instance ${name}";
          }
        ]) config.mares.services.postgresql-backup
      );

      systemd.tmpfiles.rules = map (location: "d '${location}' 0700 postgres - - -") (
        lib.unique (lib.mapAttrsToList (_: cfg: cfg.location) (fullBackups // dbBackups))
      );

      systemd.services = fullBackupServices // dbBackupServices;
    };
}
