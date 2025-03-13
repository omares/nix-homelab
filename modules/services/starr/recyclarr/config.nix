{
  lib,
  config,
  mares,
  ...
}:

let
  cfg = config.mares.services.starr;
in
{
  config = lib.mkIf (cfg.enable && cfg.recyclarr.enable) {

    services.recyclarr = {
      configuration = {
        radarr = {
          starr-radarr-01 = {
            base_url = "https://radarr.${mares.proxy.domain}";
            api_key._secret = "/run/credentials/recyclarr.service/radarr-api_key";

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
              { template = "radarr-quality-definition-movie"; }
              { template = "radarr-custom-formats-uhd-remux-web-german"; }
              { template = "radarr-quality-profile-uhd-remux-web-german"; }

              { template = "radarr-quality-profile-anime"; }
              { template = "radarr-custom-formats-anime"; }
            ];

            quality_profiles = [
              {
                name = "Remux + WEB 2160p (GER)";
                # min_format_score = 10000; # Uncomment this line to skip English Releases
              }
            ];

            custom_formats = [
              #
              # Movie custom formats
              #

              # Downgrade German Audio only
              {
                trash_ids = [ "86bc3115eb4e9873ac96904a4a68e19e" ]; # German
                assign_scores_to = [
                  {
                    name = "Remux + WEB 2160p (GER)";
                    score = -20000;
                  }
                ];
              }

              ### Audio
              {
                trash_ids = [
                  # Uncomment the next section to enable Advanced Audio Formats
                  # "496f355514737f7d83bf7aa4d24f8169" # TrueHD Atmos
                  # "2f22d89048b01681dde8afe203bf2e95" # DTS X
                  # "417804f7f2c4308c1f4c5d380d4c4475" # ATMOS (undefined)
                  "1af239278386be2919e1bcee0bde047e" # DD+ ATMOS
                  # "3cafb66171b47f226146a0770576870f" # TrueHD
                  # "dcf3ec6938fa32445f590a4da84256cd" # DTS-HD MA
                  # "a570d4a0e56a2874b64e5bfa55202a1b" # FLAC
                  # "e7c2fcae07cbada050a0af3357491d7b" # PCM
                  # "8e109e50e0a0b83a5098b056e13bf6db" # DTS-HD HRA
                  "185f1dd7264c4562b9022d963ac37424" # DD+
                  # "f9f847ac70a0af62ea4a08280b859636" # DTS-ES
                  # "1c1a4c5e823891c75bc50380a6866f73" # DTS
                  # "240770601cc226190c367ef59aba7463" # AAC
                  # "c2998bd0d90ed5621d8df281e839436e" # DD
                ];
                assign_scores_to = [
                  {
                    name = "Remux + WEB 2160p (GER)";
                  }
                ];
              }

              ### Movie Versions
              {
                trash_ids = [
                  # Uncomment any of the following lines to prefer these movie versions
                  # "0f12c086e289cf966fa5948eac571f44" # Hybrid
                  # "570bc9ebecd92723d2d21500f4be314c" # Remaster
                  "eca37840c13c6ef2dd0262b141a5482f" # 4K Remaster
                  # "e0c07d59beb37348e975a930d5e50319" # Criterion Collection
                  # "9d27d9d2181838f76dee150882bdc58c" # Masters of Cinema
                  # "db9b4c4b53d312a3ca5f1378f6440fc9" # Vinegar Syndrome
                  # "957d0f44b592285f26449575e8b1167e" # Special Edition
                  "eecf3a857724171f968a66cb5719e152" # IMAX
                  "9f6cbff8cfe4ebbc1bde14c7b7bec0de" # IMAX Enhanced
                ];
                assign_scores_to = [
                  {
                    name = "Remux + WEB 2160p (GER)";
                  }
                ];
              }

              ### Optional
              {
                trash_ids = [
                  "b6832f586342ef70d9c128d40c07b872" # Bad Dual Groups
                  "90cedc1fea7ea5d11298bebd3d1d3223" # EVO (no WEBDL)
                  "ae9b7c9ebde1f3bd336a8cbd1ec4c5e5" # No-RlsGroup
                  "7357cf5161efbf8c4d5d0c30b4815ee2" # Obfuscated
                  "5c44f52a8714fdd79bb4d98e2673be1f" # Retags
                  "f537cf427b64c38c8e36298f657e4828" # Scene
                ];
                assign_scores_to = [
                  {
                    name = "Remux + WEB 2160p (GER)";
                  }
                ];
              }

              ### HDR / DV
              {
                trash_ids = [
                  # Comment out the next line if you and all of your users' setups are fully DV compatible
                  "923b6abef9b17f937fab56cfcf89e1f1" # DV (WEBDL)

                  # HDR10+ Boost - Uncomment the next two lines if any of your devices DO support HDR10+
                  "b17886cb4158d9fea189859409975758" # HDR10Plus Boost
                  "55a5b50cb416dea5a50c4955896217ab" # DV HDR10+ Boost
                ];
                assign_scores_to = [
                  {
                    name = "Remux + WEB 2160p (GER)";
                  }
                ];
              }

              ### Optional SDR
              # Only ever use ONE of the following custom formats:
              # SDR - block ALL SDR releases
              # SDR (no WEBDL) - block UHD/4k Remux and Bluray encode SDR releases, but allow SDR WEB
              {
                trash_ids = [
                  # "9c38ebb7384dada637be8899efa68e6f" # SDR
                  "25c12f78430a3a23413652cbd1d48d77" # SDR (no WEBDL)
                ];
                assign_scores_to = [
                  {
                    name = "Remux + WEB 2160p (GER)";
                  }
                ];
              }

              ### x265 - IMPORTANT: Only use on of the options below.
              {
                trash_ids = [
                  "839bea857ed2c0a8e084f3cbdbd65ecb" # Uncomment this line to allow HDR/DV x265 HD releases
                ];
                assign_scores_to = [
                  {
                    name = "Remux + WEB 2160p (GER)";
                  }
                ];
              }
              {
                trash_ids = [
                  # "dc98083864ea246d05a42df0d05f81cc" # Uncomment this line to block all x265 HD releases
                ];
                assign_scores_to = [
                  {
                    name = "Remux + WEB 2160p (GER)";
                    score = -35000;
                  }
                ];
              }

              ### Generated Dynamic HDR
              {
                trash_ids = [
                  # "e6886871085226c3da1830830146846c" # Uncomment this line to block Generated Dynamic HDR
                ];
                assign_scores_to = [
                  {
                    name = "Remux + WEB 2160p (GER)";
                    score = -35000;
                  }
                ];
              }

              #
              # Anime custom formats
              #
              {
                trash_ids = [ "064af5f084a0a24458cc8ecd3220f93f" ]; # Uncensored
                assign_scores_to = [
                  {
                    name = "Remux-1080p - Anime";
                    score = 0; # Adjust scoring as desired
                  }
                ];
              }
              {
                trash_ids = [ "a5d148168c4506b55cf53984107c396e" ]; # 10bit
                assign_scores_to = [
                  {
                    name = "Remux-1080p - Anime";
                    score = 0; # Adjust scoring as desired
                  }
                ];
              }
              {
                trash_ids = [ "4a3b087eea2ce012fcc1ce319259a3be" ]; # Anime Dual Audio
                assign_scores_to = [
                  {
                    name = "Remux-1080p - Anime";
                    score = 0; # Adjust scoring as desired
                  }
                ];
              }
            ];
          };
        };

        sonarr = {
          starr-sonarr-01 = {
            base_url = "https://sonarr.${mares.proxy.domain}";
            api_key._secret = "/run/credentials/recyclarr.service/sonarr-api_key";

            delete_old_custom_formats = true;
            replace_existing_custom_formats = true;

            media_naming = {
              series = "jellyfin-tvdb";
              episodes = {
                rename = true;
              };
            };

            include = [
              { template = "sonarr-quality-definition-series"; }
              { template = "sonarr-v4-custom-formats-uhd-remux-web-german"; }
              { template = "sonarr-v4-quality-profile-uhd-remux-web-german"; }

              { template = "sonarr-quality-definition-anime"; }
              { template = "sonarr-v4-quality-profile-anime"; }
              { template = "sonarr-v4-custom-formats-anime"; }
            ];

            quality_profiles = [
              {
                name = "UHD Remux + WEB (GER)";
                # min_format_score = 10000; # Uncomment this line to skip English Releases
              }
            ];

            custom_formats = [
              #
              # Series custom formats
              #

              # Downgrade German Audio only
              {
                trash_ids = [ "8a9fcdbb445f2add0505926df3bb7b8a" ]; # German
                assign_scores_to = [
                  {
                    name = "UHD Remux + WEB (GER)";
                    score = -20000;
                  }
                ];
              }

              ### Optional
              {
                trash_ids = [
                  "32b367365729d530ca1c124a0b180c64" # Bad Dual Groups
                  "82d40da2bc6923f41e14394075dd4b03" # No-RlsGroup
                  "e1a997ddb54e3ecbfe06341ad323c458" # Obfuscated
                  "06d66ab109d4d2eddb2794d21526d140" # Retags
                  "1b3994c551cbb92a2c781af061f4ab44" # Scene
                ];
                assign_scores_to = [
                  {
                    name = "UHD Remux + WEB (GER)";
                  }
                ];
              }

              ### HDR / DV
              {
                trash_ids = [
                  # Comment out the next line if you and all of your users' setups are fully DV compatible
                  "9b27ab6498ec0f31a3353992e19434ca" # DV (WEBDL)

                  # HDR10+ Boost - Uncomment the next two lines if any of your devices DO support HDR10+
                  "0dad0a507451acddd754fe6dc3a7f5e7" # HDR10Plus Boost
                  "385e9e8581d33133c3961bdcdeffb7b4" # DV HDR10+ Boost
                ];
                assign_scores_to = [
                  {
                    name = "UHD Remux + WEB (GER)";
                  }
                ];
              }

              ### Optional SDR
              # Only ever use ONE of the following custom formats:
              # SDR - block ALL SDR releases
              # SDR (no WEBDL) - block UHD/4k Remux and Bluray encode SDR releases, but allow SDR WEB
              {
                trash_ids = [
                  # "2016d1676f5ee13a5b7257ff86ac9a93" # SDR
                  "83304f261cf516bb208c18c54c0adf97" # SDR (no WEBDL)
                ];
                assign_scores_to = [
                  {
                    name = "UHD Remux + WEB (GER)";
                  }
                ];
              }

              ### x265 - IMPORTANT: Only use on of below options.
              {
                trash_ids = [
                  "9b64dff695c2115facf1b6ea59c9bd07" # Uncomment this to allow only HDR/DV x265 HD releases
                ];
                assign_scores_to = [
                  {
                    name = "UHD Remux + WEB (GER)";
                  }
                ];
              }
              {
                trash_ids = [
                  # "47435ece6b99a0b477caf360e79ba0bb" # Uncomment this to block all x265 HD releases
                ];
                assign_scores_to = [
                  {
                    name = "UHD Remux + WEB (GER)";
                    score = -35000;
                  }
                ];
              }

              #
              # Anime custom formats
              #

              {
                trash_ids = [ "026d5aadd1a6b4e550b134cb6c72b3ca" ]; # Uncensored
                assign_scores_to = [
                  {
                    name = "Remux-1080p - Anime";
                    score = 0; # Adjust scoring as desired
                  }
                ];
              }
              {
                trash_ids = [ "b2550eb333d27b75833e25b8c2557b38" ]; # 10bit
                assign_scores_to = [
                  {
                    name = "Remux-1080p - Anime";
                    score = 0; # Adjust scoring as desired
                  }
                ];
              }
              {
                trash_ids = [ "418f50b10f1907201b6cfdf881f467b7" ]; # Anime Dual Audio
                assign_scores_to = [
                  {
                    name = "Remux-1080p - Anime";
                    score = 0; # Adjust scoring as desired
                  }
                ];
              }
            ];
          };
        };
      };
      user = cfg.recyclarr.user;
      group = cfg.group;
    };
  };
}
