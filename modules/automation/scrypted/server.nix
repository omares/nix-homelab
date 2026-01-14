{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.mares.automation.scrypted;
  serviceCfg = config.mares.services.scrypted;
  isServer = cfg.role == "server";
  hasPlugins = cfg.plugins != [ ];

  plugins = pkgs.callPackage ../../../packages/scrypted/plugins { };

  # Build list of plugin packages from names
  pluginPackages = map (name: plugins.${name}) cfg.plugins;

  # Sideload script for a single plugin
  sideloadPlugin = pkg: ''
    echo "Sideloading ${pkg.pluginName}..."

    # Setup - register plugin metadata
    if ! curl -sf -X POST \
      "https://127.0.0.1:10443/web/component/script/setup?npmPackage=${pkg.pluginName}" \
      -H "Content-Type: application/json" \
      -d @${pkg}/package.json \
      --insecure; then
      echo "  Warning: setup failed for ${pkg.pluginName}"
    fi

    # Deploy - upload plugin zip
    if ! curl -sf -X POST \
      "https://127.0.0.1:10443/web/component/script/deploy?npmPackage=${pkg.pluginName}" \
      -H "Content-Type: application/zip" \
      --data-binary @${pkg}/plugin.zip \
      --insecure; then
      echo "  Warning: deploy failed for ${pkg.pluginName}"
    fi
  '';

  sideloadScript = pkgs.writeShellScript "scrypted-sideload" ''
    set -euo pipefail

    echo "Waiting for Scrypted API..."
    for i in $(seq 1 30); do
      if curl -sf "https://127.0.0.1:10443/login" --insecure >/dev/null 2>&1; then
        echo "Scrypted API ready"
        break
      fi
      if [ "$i" -eq 30 ]; then
        echo "Timeout waiting for Scrypted API"
        exit 1
      fi
      echo "  Waiting... ($i/30)"
      sleep 2
    done

    ${lib.concatMapStrings sideloadPlugin pluginPackages}

    echo "Sideload complete"
  '';
in
{
  config = lib.mkIf (cfg.enable && isServer) {

    mares.services.scrypted = {
      enable = true;
      package = pkgs.callPackage ../../../packages/scrypted/package.nix { };
      openFirewall = true;
      extraEnvironment = lib.mkMerge [
        {
          SCRYPTED_CLUSTER_LABELS = "storage";
          SCRYPTED_CLUSTER_MODE = "server";
          SCRYPTED_CLUSTER_ADDRESS = cfg.serverHost;
        }
        (lib.mkIf hasPlugins {
          SCRYPTED_ADMIN_USERNAME = "admin";
          SCRYPTED_ADMIN_ADDRESS = "127.0.0.1";
        })
      ];
      environmentFiles = [ config.sops.secrets.scrypted-environment.path ];
    };

    systemd.services.scrypted = {
      wants = [ "sops-nix.service" ];
      after = [ "sops-nix.service" ];
    };

    # Sideload service - runs after scrypted to install plugins
    systemd.services.scrypted-sideload = lib.mkIf hasPlugins {
      description = "Sideload Scrypted plugins";
      after = [ "scrypted.service" ];
      requires = [ "scrypted.service" ];
      wantedBy = [ "multi-user.target" ];

      path = [ pkgs.curl ];

      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = sideloadScript;
        User = serviceCfg.user;
        Group = serviceCfg.group;
      };
    };
  };
}
