{
  config,
  lib,
  cluster,
  ...
}:

let
  cfg = config.cluster.services.starr;
in
{
  config = lib.mkIf (cfg.enable && cfg.jellyfin.enable) {

    sops.templates."jellyfin-network.xml" = {
      content = cluster.lib.generators.toXML { } {
        BaseUrl = "";
        EnableHttps = false;
        RequireHttps = false;
        InternalHttpPort = 8096;
        InternalHttpsPort = 8920;
        PublicHttpPort = 8096;
        PublicHttpsPort = 8920;
        AutoDiscovery = true;
        EnableUPnP = false;
        EnableIPv4 = true;
        EnableIPv6 = false;
        EnableRemoteAccess = true;
        LocalNetworkSubnets = [ ];
        LocalNetworkAddresses = [
          { string = "192.168.20.26"; }
        ];
        KnownProxies = [ ];
        IgnoreVirtualInterfaces = true;
        VirtualInterfaceNames = [
          { string = "veth"; }
        ];
        EnablePublishedServerUriByRequest = false;
        PublishedServerUriBySubnet = [ ];
        RemoteIPFilter = [ ];
        IsRemoteIPFilterBlacklist = false;
      };

      owner = cfg.jellyfin.user;
      group = cfg.group;
      mode = "0660";

      restartUnits = [ "jellyfin.service" ];
    };

    services.jellyfin = {
      enable = true;
      dataDir = "${cfg.pathPrefix}/jellyfin";
      group = cfg.group;
      openFirewall = true;
    };

    nixpkgs.overlays = [
      (final: prev: {
        jellyfin-web = prev.jellyfin-web.overrideAttrs (
          finalAttrs: previousAttrs: {
            installPhase = ''
              runHook preInstall

              # this is the important line
              sed -i "s#</head>#<script src=\"configurationpage?name=skip-intro-button.js\"></script></head>#" dist/index.html

              mkdir -p $out/share
              cp -a dist $out/share/jellyfin-web

              runHook postInstall
            '';
          }
        );
      })
    ];

    cluster.storage.truenas.media = {
      enable = cfg.jellyfin.mountStorage;
    };

    # Give jellyfin access to hardware devices
    users.users.jellyfin = {
      uid = config.ids.uids.jellyfin;
      extraGroups = [
        "video"
        "render"
      ];
    };

    systemd.services.jellyfin = {
      serviceConfig = {
        # Device access
        DeviceAllow = [
          "/dev/dri/renderD128" # GPU render node for encoding/decoding
          "/dev/dri/card0" # Main GPU device for display/acceleration
        ];
      };

      wants = [
        # "sops-nix.service"
        "mnt-media.mount"
      ];
      after = [
        # "sops-nix.service"
        "mnt-media.mount"
      ];
    };
  };
}
