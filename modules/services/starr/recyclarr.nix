{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.cluster.services.starr;
  toYaml = pkgs.formats.yaml { };
in
{
  imports = [
    ../recyclarr.nix
  ];

  config = lib.mkIf (cfg.enable && cfg.recyclarr.enable) {
    sops.templates."recyclarr.yaml" = {
      file = toYaml.generate "recyclarr-config" {
        sonarr = {
          starr-sonarr-01 = {
            base_url = "https://sonarr.mares.id";
            api_key = config.sops.placeholder.sonarr-api_key;

            delete_old_custom_formats = true;
            replace_existing_custom_formats = true;

            media_naming = {
              series = "jellyfin-tvdb";
              episodes = {
                rename = true;
              };
            };

            include = [
              # Comment out any of the following includes to disable them
              { template = "sonarr-quality-definition-series"; }
              # Choose between the standard or alternative quality profile setup (choose one only)
              # { template = "sonarr-v4-quality-profile-web-2160p"; }
              { template = "sonarr-v4-quality-profile-web-2160p-alternative"; }
              { template = "sonarr-v4-custom-formats-web-2160p"; }
            ];

            quality_profiles = [
              {
                name = "SD";
                reset_unmatched_scores = {
                  enabled = true;
                  except = [
                    "Language: German + Original"
                    "ML"
                    "DL"
                  ];
                };
              }
            ];

            # Custom Formats: https://recyclarr.dev/wiki/yaml/config-reference/custom-formats/
            custom_formats = [
              # HDR Formats
              {
                trash_ids = [
                  # Comment out the next line if you and all of your users' setups are fully DV compatible
                  "9b27ab6498ec0f31a3353992e19434ca" # DV (WEBDL)

                  # HDR10+ Boost - Uncomment the next two lines if any of your devices DO support HDR10+
                  "0dad0a507451acddd754fe6dc3a7f5e7" # HDR10+ Boost
                  "385e9e8581d33133c3961bdcdeffb7b4" # DV HDR10+ Boost
                ];
                assign_scores_to = [
                  { name = "WEB-2160p"; }
                ];
              }

              # Optional
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
                    name = "WEB-2160p";
                    score = -10000;
                  }
                ];
              }

              {
                trash_ids = [
                  # Uncomment the next six lines to allow x265 HD releases with HDR/DV
                  # "47435ece6b99a0b477caf360e79ba0bb" # x265 (HD)
                ];
                assign_scores_to = [
                  { name = "WEB-2160p"; }
                ];
              }

              # Optional SDR
              # Only ever use ONE of the following custom formats:
              # SDR - block ALL SDR releases
              # SDR (no WEBDL) - block UHD/4k Remux and Bluray encode SDR releases, but allow SDR WEB
              {
                trash_ids = [
                  "2016d1676f5ee13a5b7257ff86ac9a93" # SDR
                  # "83304f261cf516bb208c18c54c0adf97" # SDR (no WEBDL)
                ];
                assign_scores_to = [
                  {
                    name = "WEB-2160p";
                    score = -10000;
                  }
                ];
              }
            ];

          };
        };
        radarr = {
          starr-radarr-01 = {
            base_url = "https://radarr.mares.id";
            api_key = config.sops.placeholder.radarr-api_key;

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
              { template = "radarr-quality-profile-uhd-bluray-web"; }
              { template = "radarr-custom-formats-uhd-bluray-web"; }
            ];

            quality_profiles = [
              {
                name = "SD";
                reset_unmatched_scores = {
                  enabled = true;
                  except = [
                    "Language: German + Original"
                    "ML"
                    "DL"
                  ];
                };
              }
            ];

            custom_formats = [
              # Audio
              {
                trash_ids = [
                  "1af239278386be2919e1bcee0bde047e" # DD+ ATMOS
                  "185f1dd7264c4562b9022d963ac37424" # DD+
                  # Uncomment for Advanced Audio Formats
                  # "496f355514737f7d83bf7aa4d24f8169" # TrueHD Atmos
                  # "2f22d89048b01681dde8afe203bf2e95" # DTS X
                  # "417804f7f2c4308c1f4c5d380d4c4475" # ATMOS (undefined)
                  # "3cafb66171b47f226146a0770576870f" # TrueHD
                  # "dcf3ec6938fa32445f590a4da84256cd" # DTS-HD MA
                  # "a570d4a0e56a2874b64e5bfa55202a1b" # FLAC
                  # "e7c2fcae07cbada050a0af3357491d7b" # PCM
                  # "8e109e50e0a0b83a5098b056e13bf6db" # DTS-HD HRA
                  # "f9f847ac70a0af62ea4a08280b859636" # DTS-ES
                  # "1c1a4c5e823891c75bc50380a6866f73" # DTS
                  # "240770601cc226190c367ef59aba7463" # AAC
                  # "c2998bd0d90ed5621d8df281e839436e" # DD
                ];
                assign_scores_to = [
                  { name = "UHD Bluray + WEB"; }
                ];
              }

              # Movie Versions
              {
                trash_ids = [
                  "eca37840c13c6ef2dd0262b141a5482f" # 4K Remaster
                  "eecf3a857724171f968a66cb5719e152" # IMAX
                  "9f6cbff8cfe4ebbc1bde14c7b7bec0de" # IMAX Enhanced
                  # Uncomment to prefer these versions
                  # "570bc9ebecd92723d2d21500f4be314c" # Remaster
                  # "e0c07d59beb37348e975a930d5e50319" # Criterion Collection
                  # "9d27d9d2181838f76dee150882bdc58c" # Masters of Cinema
                  # "db9b4c4b53d312a3ca5f1378f6440fc9" # Vinegar Syndrome
                  # "957d0f44b592285f26449575e8b1167e" # Special Edition
                ];
                assign_scores_to = [
                  { name = "UHD Bluray + WEB"; }
                ];
              }

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
                  { name = "UHD Bluray + WEB"; }
                ];
              }

              {
                trash_ids = [
                  # Uncomment for x265 HD with HDR/DV
                  # "dc98083864ea246d05a42df0d05f81cc" # x265 (HD)
                ];
                assign_scores_to = [
                  { name = "UHD Bluray + WEB"; }
                ];
              }

              {
                trash_ids = [
                  # Comment out if all setups are DV compatible
                  "923b6abef9b17f937fab56cfcf89e1f1" # DV (WEBDL)

                  # HDR10+ Boost - Uncomment if devices support HDR10+
                  "b17886cb4158d9fea189859409975758" # HDR10Plus Boost
                  "55a5b50cb416dea5a50c4955896217ab" # DV HDR10+ Boost
                ];
                assign_scores_to = [
                  {
                    name = "UHD Bluray + WEB";
                  }
                ];
              }

              # Optional SDR / Avoid problematic x265
              {
                trash_ids = [
                  "9c38ebb7384dada637be8899efa68e6f" # SDR
                  "25c12f78430a3a23413652cbd1d48d77" # SDR (no WEBDL)
                  "839bea857ed2c0a8e084f3cbdbd65ecb" # x265 (no HDR/DV) - avoid for 4K
                  "dc98083864ea246d05a42df0d05f81cc" # x265 (HD) - avoid upscaled content
                ];
                assign_scores_to = [
                  {
                    name = "UHD Bluray + WEB";
                  }
                ];
              }
            ];

          };
        };
      };

      owner = cfg.recyclarr.user;
      group = cfg.group;

      restartUnits = [ "recyclarr.service" ];
    };

    cluster.services.recyclarr = {
      enable = true;
      configFile = config.sops.templates."recyclarr.yaml".path;
      user = cfg.recyclarr.user;
      group = cfg.group;
    };

    systemd.services.recyclarr = {
      wants = [
        "sops-nix.service"
      ];
      after = [
        "sops-nix.service"
      ];
    };
  };
}
