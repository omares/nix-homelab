{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config.mares.starr;
in
{
  config = lib.mkIf (cfg.enable && cfg.jellyfin.enable) {

    environment.systemPackages = [
      pkgs.jellyfin
      pkgs.jellyfin-web
      pkgs.jellyfin-ffmpeg
    ];

    # To view the passed configuration, check config.nix.
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

    # Give jellyfin access to hardware devices
    users.users.jellyfin = {
      uid = config.ids.uids.jellyfin;
      extraGroups = [
        "video"
        "render"
      ];
    };

    systemd.services.jellyfin = {
      serviceConfig.DeviceAllow = [
        "/dev/dri/renderD128" # GPU render node for encoding/decoding
        "/dev/dri/card0" # Main GPU device for display/acceleration
      ];
    };
  };
}
