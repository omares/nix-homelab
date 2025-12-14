{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.mares.database.postgres.upgrade;
  pgCfg = config.services.postgresql;
in
{
  options.mares.database.postgres.upgrade = {
    enable = lib.mkEnableOption "PostgreSQL upgrade script";

    targetPackage = lib.mkOption {
      type = lib.types.package;
      description = "PostgreSQL package to upgrade to";
      example = lib.literalExpression "pkgs.postgresql_17";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      (pkgs.writeScriptBin "upgrade-pg-cluster" ''
        set -eux

        # Derive paths from current config and target package
        OLDDATA="${pgCfg.dataDir}"
        OLDBIN="${pgCfg.finalPackage}/bin"

        NEWDATA="$(dirname "$OLDDATA")/${cfg.targetPackage.psqlSchema}"
        NEWBIN="${cfg.targetPackage}/bin"

        echo "=== PostgreSQL Upgrade ==="
        echo "Old: $OLDDATA ($("$OLDBIN/postgres" --version))"
        echo "New: $NEWDATA ($("$NEWBIN/postgres" --version))"
        echo ""

        read -p "Stop postgresql and begin upgrade? [y/N] " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
          echo "Aborted."
          exit 1
        fi

        systemctl stop postgresql

        install -d -m 0700 -o postgres -g postgres "$NEWDATA"
        cd "$NEWDATA"

        sudo -u postgres "$NEWBIN/initdb" -D "$NEWDATA" ${lib.escapeShellArgs pgCfg.initdbArgs}

        sudo -u postgres "$NEWBIN/pg_upgrade" \
          --old-datadir "$OLDDATA" --new-datadir "$NEWDATA" \
          --old-bindir "$OLDBIN" --new-bindir "$NEWBIN" \
          "$@"

        echo ""
        echo "=== Upgrade Complete ==="
        echo "Next steps:"
        echo "1. Update postgresql.nix: package = pkgs.postgresql_${cfg.targetPackage.psqlSchema};"
        echo "2. Set upgrade.enable = false"
        echo "3. Deploy the updated configuration"
        echo "4. Run: sudo -u postgres vacuumdb --all --analyze-in-stages"
      '')
    ];
  };
}
