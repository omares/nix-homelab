{
  lib,
  config,
  mares,
  ...
}:

let
  cfg = config.mares.starr;

  # Custom Format overrides for device compatibility and quality preferences
  # - Samsung TV: Supports HDR10+, Dolby Vision
  # - Apple devices (iPhone/iPad/Mac): Limited DV support (Profile 5/8 with CMv2.9 only)
  #
  # Quality priority: 4K German DL > 4K English > 1080p German DL > 1080p English
  # This is achieved by scoring 2160p (+15000) higher than German DL (+11000)
  #
  # Based on TRaSH Guide: https://trash-guides.info/Radarr/radarr-setup-quality-profiles-german-en/

  # Radarr custom formats
  radarrCustomFormats = profileName: [
    # German 2160p Booster - ensures 4K is always preferred over 1080p regardless of language
    # Score +15000 > German DL +11000, so: 4K English (+15000) > 1080p German DL (+11000)
    {
      trash_ids = [ "cc7b1e64e2513a6a271090cdfafaeb55" ]; # German 2160p Booster
      assign_scores_to = [
        {
          name = profileName;
          score = 15000;
        }
      ];
    }
    # HDR catch-all - required for proper HDR scoring
    {
      trash_ids = [ "493b6d1dbec3c3364c59d7607f7e3405" ]; # HDR
      assign_scores_to = [
        {
          name = profileName;
          score = 500;
        }
      ];
    }
    # HDR10+ Boost - Samsung TV supports HDR10+
    {
      trash_ids = [ "caa37d0df9c348912df1fb1d88f9273a" ]; # HDR10+ Boost
      assign_scores_to = [
        {
          name = profileName;
          score = 100;
        }
      ];
    }
    # Block DV without HDR fallback - prevents playback issues on Apple devices
    {
      trash_ids = [ "923b6abef9b17f937fab56cfcf89e1f1" ]; # DV (WEBDL)
      assign_scores_to = [
        {
          name = profileName;
          score = -10000;
        }
      ];
    }
  ];

  # Sonarr custom formats (different trash_ids than Radarr!)
  sonarrCustomFormats = profileName: [
    # German 2160p Booster - ensures 4K is always preferred over 1080p regardless of language
    {
      trash_ids = [ "b493cd40d8a3bbf2839127a706bdb673" ]; # German 2160p Booster
      assign_scores_to = [
        {
          name = profileName;
          score = 15000;
        }
      ];
    }
    # HDR catch-all
    {
      trash_ids = [ "505d871304820ba7106b693be6fe4a9e" ]; # HDR
      assign_scores_to = [
        {
          name = profileName;
          score = 500;
        }
      ];
    }
    # HDR10+ Boost
    {
      trash_ids = [ "0c4b99df9206d2cfac3c05ab897dd62a" ]; # HDR10+ Boost
      assign_scores_to = [
        {
          name = profileName;
          score = 100;
        }
      ];
    }
    # Block DV without HDR fallback
    {
      trash_ids = [ "9b27ab6498ec0f31a3353992e19434ca" ]; # DV (WEBDL)
      assign_scores_to = [
        {
          name = profileName;
          score = -10000;
        }
      ];
    }
  ];

  # Quality profile with merged 4K + 1080p qualities (no 720p, no Remux)
  # Allows 1080p as fallback when 4K isn't available, upgrades to 4K when it becomes available
  # Must use "Merged QPs" name to satisfy template's until_quality setting
  mergedQualities = [
    {
      name = "Merged QPs";
      qualities = [
        "Bluray-2160p"
        "WEBDL-2160p"
        "WEBRip-2160p"
        "Bluray-1080p"
        "WEBDL-1080p"
        "WEBRip-1080p"
      ];
    }
  ];
in
{
  config = lib.mkIf (cfg.enable && cfg.recyclarr.enable) {

    services.recyclarr = {
      configuration = {
        #
        # RADARR - Movies
        #
        radarr = {
          starr-radarr-01 = {
            base_url = mares.infrastructure.nodes.starr-radarr-01.proxy.url;
            api_key._secret = "/run/secrets/radarr-api_key";

            delete_old_custom_formats = true;
            replace_existing_custom_formats = true;

            media_naming = {
              folder = "jellyfin-tmdb";
              movie = {
                rename = true;
                standard = "jellyfin-tmdb";
              };
            };

            include = [
              # Quality definitions
              { template = "radarr-quality-definition-movie"; }

              # UHD Bluray + WEB (German DL) - Main profile
              # Prefers German DL (dual language), falls back to English
              # Uses 4K encodes (~20GB) instead of Remux (~50GB) to save storage
              { template = "radarr-custom-formats-uhd-bluray-web-german"; }
              { template = "radarr-quality-profile-uhd-bluray-web-german"; }

              # Anime - 1080p, English/Japanese audio (no German DL needed)
              { template = "radarr-quality-profile-anime"; }
              { template = "radarr-custom-formats-anime"; }
            ];

            # Quality profile with 1080p fallback
            # Priority: 4K German DL > 4K English > 1080p German DL > 1080p English
            quality_profiles = [
              {
                name = "UHD Bluray + WEB (GER)";
                qualities = mergedQualities;
              }
            ];

            # Custom format overrides for resolution priority and device compatibility
            custom_formats = radarrCustomFormats "UHD Bluray + WEB (GER)";
          };
        };

        #
        # SONARR - Series
        #
        sonarr = {
          starr-sonarr-01 = {
            base_url = mares.infrastructure.nodes.starr-sonarr-01.proxy.url;
            api_key._secret = "/run/secrets/sonarr-api_key";

            delete_old_custom_formats = true;
            replace_existing_custom_formats = true;

            media_naming = {
              series = "jellyfin-tvdb";
              episodes = {
                rename = true;
              };
            };

            include = [
              # Quality definitions
              { template = "sonarr-quality-definition-series"; }

              # UHD Bluray + WEB (German DL) - Main profile
              { template = "sonarr-v4-custom-formats-uhd-bluray-web-german"; }
              { template = "sonarr-v4-quality-profile-uhd-bluray-web-german"; }

              # Anime - 1080p, English/Japanese audio
              { template = "sonarr-quality-definition-anime"; }
              { template = "sonarr-v4-quality-profile-anime"; }
              { template = "sonarr-v4-custom-formats-anime"; }
            ];

            # Quality profile with 1080p fallback
            # Priority: 4K German DL > 4K English > 1080p German DL > 1080p English
            quality_profiles = [
              {
                name = "UHD Bluray + WEB (GER)";
                qualities = mergedQualities;
              }
            ];

            # Custom format overrides for resolution priority and device compatibility
            custom_formats = sonarrCustomFormats "UHD Bluray + WEB (GER)";
          };
        };
      };

      user = cfg.recyclarr.user;
      group = cfg.group;
    };
  };
}
