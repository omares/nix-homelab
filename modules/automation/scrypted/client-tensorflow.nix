{
  lib,
  config,
  ...
}:
let
  cfg = config.cluster.automation.scrypted;
  isTensorflowClient = cfg.role == "client-tensorflow";
in
{
  imports = [ ./common.nix ];

  config = lib.mkIf (cfg.enable && isTensorflowClient) {
    users.users.scrypted = {
      isSystemUser = true;
      group = config.services.scrypted.group;
      home = config.services.scrypted.installPath;
      createHome = true;
      description = "Scrypted service user";
      extraGroups = [
        "podman"
        "coral"
      ];
    };

    users.groups.${config.services.scrypted.group} = { };

    hardware.coral.usb.enable = true;

    services.udev.extraRules = ''
      SUBSYSTEM=="usb", ATTRS{idVendor}=="1a6e", ATTRS{idProduct}=="089a", GROUP="coral", MODE="0666", TAG+="uaccess
      SUBSYSTEM=="usb", ATTRS{idVendor}=="18d1", ATTRS{idProduct}=="9302", GROUP="coral", MODE="0666", TAG+="uaccess
    '';

    # Runtime configuration
    virtualisation.podman = {
      enable = true;
      autoPrune.enable = true;
      dockerSocket.enable = true;
      dockerCompat = true;
      defaultNetwork.settings = {
        # Required for container networking to be able to use names.
        dns_enabled = true;
      };
    };

    # Enable container name DNS for non-default Podman networks.
    # https://github.com/NixOS/nixpkgs/issues/226365
    networking.firewall.interfaces."podman+".allowedUDPPorts = [ 53 ];

    virtualisation.oci-containers.backend = "podman";

    # Container configuration
    virtualisation.oci-containers.containers."scrypted" = {
      image = "ghcr.io/koush/scrypted";
      volumes = [
        "/var/lib/scrypted:/server/volume:rw"
      ];

      environment = {
        SCRYPTED_CLUSTER_LABELS = "compute,transcode,@scrypted/tensorflow-lite";
        SCRYPTED_CLUSTER_MODE = "client";
        SCRYPTED_CLUSTER_SERVER = cfg.serverHost;
        SCRYPTED_CLUSTER_WORKER_NAME = cfg.workerName;
      };
      environmentFiles = [ config.sops.secrets.scrypted-environment.path ];

      extraOptions = [
        "--device=/dev/bus/usb:/dev/bus/usb:rwm"
        "--device=/dev/dri:/dev/dri:rwm"
        "--network=host"
        "--group-add=${toString config.ids.gids.scrypted}"
      ];
    };

    # Systemd service configuration
    systemd.services."podman-scrypted" = {
      serviceConfig.Restart = lib.mkOverride 90 "always";
      partOf = [ "podman-compose-scrypted-root.target" ];
      wantedBy = [ "podman-compose-scrypted-root.target" ];
      wants = [ "sops-nix.service" ];
      after = [ "sops-nix.service" ];
    };

    # Root target
    systemd.targets."podman-compose-scrypted-root" = {
      unitConfig.Description = "Root target generated by compose2nix.";
      wantedBy = [ "multi-user.target" ];
    };
  };
}
