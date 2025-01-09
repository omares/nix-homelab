{
  pkgs,
  config,
  lib,
  cluster,
  ...
}:
let
  cfg = config.cluster.services.starr;

  branding = {
    LoginDisclaimer = "";
    CustomCss = "";
    SplashscreenEnabled = true;
  };

  encoding = {
    EncodingThreadCount = -1;
    TranscodingTempPath = "/var/cache/jellyfin/transcodes";
    FallbackFontPath = "";
    EnableFallbackFont = false;
    EnableAudioVbr = false;
    DownMixAudioBoost = 2;
    DownMixStereoAlgorithm = "None";
    MaxMuxingQueueSize = 2048;
    EnableThrottling = false;
    ThrottleDelaySeconds = 180;
    EnableSegmentDeletion = false;
    SegmentKeepSeconds = 720;
    HardwareAccelerationType = "vaapi";
    EncoderAppPathDisplay = lib.getExe pkgs.jellyfin-ffmpeg;
    VaapiDevice = "/dev/dri/renderD128";
    QsvDevice = "";
    EnableTonemapping = true;
    EnableVppTonemapping = true;
    EnableVideoToolboxTonemapping = false;
    TonemappingAlgorithm = "bt2390";
    TonemappingMode = "auto";
    TonemappingRange = "auto";
    TonemappingDesat = 0;
    TonemappingPeak = 100;
    TonemappingParam = 0;
    VppTonemappingBrightness = 16;
    VppTonemappingContrast = 1;
    H264Crf = 23;
    H265Crf = 28;
    EncoderPreset = "auto";
    DeinterlaceDoubleRate = false;
    DeinterlaceMethod = "yadif";
    EnableDecodingColorDepth10Hevc = true;
    EnableDecodingColorDepth10Vp9 = false;
    EnableDecodingColorDepth10HevcRext = false;
    EnableDecodingColorDepth12HevcRext = false;
    EnableEnhancedNvdecDecoder = true;
    PreferSystemNativeHwDecoder = true;
    EnableIntelLowPowerH264HwEncoder = true;
    EnableIntelLowPowerHevcHwEncoder = true;
    EnableHardwareEncoding = true;
    AllowHevcEncoding = true;
    AllowAv1Encoding = false;
    EnableSubtitleExtraction = true;
    HardwareDecodingCodecs = [
      { string = "h264"; }
      { string = "hevc"; }
      { string = "mpeg2video"; }
      { string = "vc1"; }
      { string = "vp8"; }
      { string = "vp9"; }
      { string = "av1"; }
    ];
    AllowOnDemandMetadataBasedKeyframeExtractionForExtensions = [
      { string = "mkv"; }
    ];
  };

  migrations = {
    Applied = [
      {
        ValueTupleOfGuidString = {
          Item1 = "9b354818-94d5-4b68-ac49-e35cb85f9d84";
          Item2 = "CreateNetworkConfiguration";
        };
      }
      {
        ValueTupleOfGuidString = {
          Item1 = "a6dcacf4-c057-4ef9-80d3-61cef9ddb4f0";
          Item2 = "MigrateMusicBrainzTimeout";
        };
      }
      {
        ValueTupleOfGuidString = {
          Item1 = "4fb5c950-1991-11ee-9b4b-0800200c9a66";
          Item2 = "MigrateNetworkConfiguration";
        };
      }
      {
        ValueTupleOfGuidString = {
          Item1 = "a8e61960-7726-4450-8f3d-82c12daabbcb";
          Item2 = "MigrateEncodingOptions";
        };
      }
      {
        ValueTupleOfGuidString = {
          Item1 = "4124c2cd-e939-4ffb-9be9-9b311c413638";
          Item2 = "DisableTranscodingThrottling";
        };
      }
      {
        ValueTupleOfGuidString = {
          Item1 = "ef103419-8451-40d8-9f34-d1a8e93a1679";
          Item2 = "CreateLoggingConfigHeirarchy";
        };
      }
      {
        ValueTupleOfGuidString = {
          Item1 = "3793eb59-bc8c-456c-8b9f-bd5a62a42978";
          Item2 = "MigrateActivityLogDatabase";
        };
      }
      {
        ValueTupleOfGuidString = {
          Item1 = "acbe17b7-8435-4a83-8b64-6fcf162cb9bd";
          Item2 = "RemoveDuplicateExtras";
        };
      }
      {
        ValueTupleOfGuidString = {
          Item1 = "5c4b82a2-f053-4009-bd05-b6fcad82f14c";
          Item2 = "MigrateUserDatabase";
        };
      }
      {
        ValueTupleOfGuidString = {
          Item1 = "06387815-c3cc-421f-a888-fb5f9992bea8";
          Item2 = "MigrateDisplayPreferencesDatabase";
        };
      }
      {
        ValueTupleOfGuidString = {
          Item1 = "a81f75e0-8f43-416f-a5e8-516ccab4d8cc";
          Item2 = "RemoveDownloadImagesInAdvance";
        };
      }
      {
        ValueTupleOfGuidString = {
          Item1 = "5bd72f41-e6f3-4f60-90aa-09869abe0e22";
          Item2 = "MigrateAuthenticationDatabase";
        };
      }
      {
        ValueTupleOfGuidString = {
          Item1 = "615dfa9e-2497-4dbb-a472-61938b752c5b";
          Item2 = "FixPlaylistOwner";
        };
      }
      {
        ValueTupleOfGuidString = {
          Item1 = "67445d54-b895-4b24-9f4c-35ce0690ea07";
          Item2 = "MigrateRatingLevels";
        };
      }
      {
        ValueTupleOfGuidString = {
          Item1 = "cf6fabc2-9fbe-4933-84a5-ffe52ef22a58";
          Item2 = "FixAudioData";
        };
      }
      {
        ValueTupleOfGuidString = {
          Item1 = "96c156a2-7a13-4b3b-a8b8-fb80c94d20c0";
          Item2 = "RemoveDuplicatePlaylistChildren";
        };
      }
      {
        ValueTupleOfGuidString = {
          Item1 = "eb58ebee-9514-4b9b-8225-12e1a40020df";
          Item2 = "AddDefaultPluginRepository";
        };
      }
      {
        ValueTupleOfGuidString = {
          Item1 = "5f86e7f6-d966-4c77-849d-7a7b40b68c4e";
          Item2 = "ReaddDefaultPluginRepository";
        };
      }
      {
        ValueTupleOfGuidString = {
          Item1 = "34a1a1c4-5572-418e-a2f8-32cdfe2668e8";
          Item2 = "AddDefaultCastReceivers";
        };
      }
      {
        ValueTupleOfGuidString = {
          Item1 = "852816e0-2712-49a9-9240-c6fc5fcad1a8";
          Item2 = "UpdateDefaultPluginRepository10.9";
        };
      }
      {
        ValueTupleOfGuidString = {
          Item1 = "4ef123d5-8eff-4b0b-869d-3aed07a60e1b";
          Item2 = "MoveTrickplayFiles";
        };
      }
    ];
  };

  network = {
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
      { string = cfg.jellyfin.bindAddress; }
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

  system = {
    LogFileRetentionDays = 3;
    IsStartupWizardCompleted = true;
    CachePath = "/var/cache/jellyfin";
    EnableMetrics = false;
    EnableNormalizedItemByNameIds = true;
    IsPortAuthorized = true;
    QuickConnectAvailable = true;
    EnableCaseSensitiveItemIds = true;
    DisableLiveTvChannelUserDataName = true;
    MetadataPath = "${cfg.pathPrefix}/jellyfin/metadata";
    PreferredMetadataLanguage = "en";
    MetadataCountryCode = "DE";
    SortReplaceCharacters = [
      { string = "."; }
      { string = "+"; }
      { string = "%"; }
    ];
    SortRemoveCharacters = [
      { string = ","; }
      { string = "&"; }
      { string = "-"; }
      { string = "{"; }
      { string = "}"; }
      { string = "'"; }
    ];
    SortRemoveWords = [
      { string = "the"; }
      { string = "a"; }
      { string = "an"; }
    ];
    MinResumePct = 5;
    MaxResumePct = 90;
    MinResumeDurationSeconds = 300;
    MinAudiobookResume = 5;
    MaxAudiobookResume = 5;
    InactiveSessionThreshold = 0;
    LibraryMonitorDelay = 60;
    LibraryUpdateDuration = 30;
    ImageSavingConvention = "Legacy";
    MetadataOptions = [
      {
        MetadataOptions = {
          ItemType = "Book";
          DisabledMetadataSavers = [ ];
          LocalMetadataReaderOrder = [ ];
          DisabledMetadataFetchers = [ ];
          MetadataFetcherOrder = [ ];
          DisabledImageFetchers = [ ];
          ImageFetcherOrder = [ ];
        };
      }
      {
        MetadataOptions = {
          ItemType = "Movie";
          DisabledMetadataSavers = [ ];
          LocalMetadataReaderOrder = [ ];
          DisabledMetadataFetchers = [ ];
          MetadataFetcherOrder = [ ];
          DisabledImageFetchers = [ ];
          ImageFetcherOrder = [ ];
        };
      }
      {
        MetadataOptions = {
          ItemType = "MusicVideo";
          DisabledMetadataSavers = [ ];
          LocalMetadataReaderOrder = [ ];
          DisabledMetadataFetchers = [
            { string = "The Open Movie Database"; }
          ];
          MetadataFetcherOrder = [ ];
          DisabledImageFetchers = [
            { string = "The Open Movie Database"; }
          ];
          ImageFetcherOrder = [ ];
        };
      }
      {
        MetadataOptions = {
          ItemType = "Series";
          DisabledMetadataSavers = [ ];
          LocalMetadataReaderOrder = [ ];
          DisabledMetadataFetchers = [ ];
          MetadataFetcherOrder = [ ];
          DisabledImageFetchers = [ ];
          ImageFetcherOrder = [ ];
        };
      }
      {
        MetadataOptions = {
          ItemType = "MusicAlbum";
          DisabledMetadataSavers = [ ];
          LocalMetadataReaderOrder = [ ];
          DisabledMetadataFetchers = [
            { string = "TheAudioDB"; }
          ];
          MetadataFetcherOrder = [ ];
          DisabledImageFetchers = [ ];
          ImageFetcherOrder = [ ];
        };
      }
      {
        MetadataOptions = {
          ItemType = "MusicArtist";
          DisabledMetadataSavers = [ ];
          LocalMetadataReaderOrder = [ ];
          DisabledMetadataFetchers = [
            { string = "TheAudioDB"; }
          ];
          MetadataFetcherOrder = [ ];
          DisabledImageFetchers = [ ];
          ImageFetcherOrder = [ ];
        };
      }
      {
        MetadataOptions = {
          ItemType = "BoxSet";
          DisabledMetadataSavers = [ ];
          LocalMetadataReaderOrder = [ ];
          DisabledMetadataFetchers = [ ];
          MetadataFetcherOrder = [ ];
          DisabledImageFetchers = [ ];
          ImageFetcherOrder = [ ];
        };
      }
      {
        MetadataOptions = {
          ItemType = "Season";
          DisabledMetadataSavers = [ ];
          LocalMetadataReaderOrder = [ ];
          DisabledMetadataFetchers = [ ];
          MetadataFetcherOrder = [ ];
          DisabledImageFetchers = [ ];
          ImageFetcherOrder = [ ];
        };
      }
      {
        MetadataOptions = {
          ItemType = "Episode";
          DisabledMetadataSavers = [ ];
          LocalMetadataReaderOrder = [ ];
          DisabledMetadataFetchers = [ ];
          MetadataFetcherOrder = [ ];
          DisabledImageFetchers = [ ];
          ImageFetcherOrder = [ ];
        };
      }
    ];
    SkipDeserializationForBasicTypes = true;
    ServerName = "starr-jellyfin-01";
    UICulture = "en-US";
    SaveMetadataHidden = false;
    ContentTypes = [ ];
    RemoteClientBitrateLimit = 0;
    EnableFolderView = false;
    EnableGroupingIntoCollections = false;
    DisplaySpecialsWithinSeasons = true;
    CodecsUsed = [ ];
    PluginRepositories = [
      {
        RepositoryInfo = {
          Name = "Jellyfin Stable";
          Url = "https://repo.jellyfin.org/files/plugin/manifest.json";
          Enabled = true;
        };
      }
      {
        RepositoryInfo = {
          Name = "Intro Skipper";
          Url = "https://manifest.intro-skipper.org/manifest.json";
          Enabled = true;
        };
      }
    ];
    EnableExternalContentInSuggestions = true;
    ImageExtractionTimeoutMs = 0;
    PathSubstitutions = [ ];
    EnableSlowResponseWarning = true;
    SlowResponseThresholdMs = 500;
    CorsHosts = [
      { string = "*"; }
    ];
    ActivityLogRetentionDays = 30;
    LibraryScanFanoutConcurrency = 0;
    LibraryMetadataRefreshConcurrency = 0;
    RemoveOldPlugins = false;
    AllowClientLogUpload = true;
    DummyChapterDuration = 0;
    ChapterImageResolution = "MatchSource";
    ParallelImageEncodingLimit = 0;
    CastReceiverApplications = [
      {
        CastReceiverApplication = {
          Id = "F007D354";
          Name = "Stable";
        };
      }
      {
        CastReceiverApplication = {
          Id = "6F511C87";
          Name = "Unstable";
        };
      }
    ];
    TrickplayOptions = {
      EnableHwAcceleration = true;
      EnableHwEncoding = true;
      EnableKeyFrameOnlyExtraction = true;
      ScanBehavior = "NonBlocking";
      ProcessPriority = "BelowNormal";
      Interval = 10000;
      WidthResolutions = [
        { int = 320; }
      ];
      TileWidth = 10;
      TileHeight = 10;
      Qscale = 4;
      JpegQuality = 90;
      ProcessThreads = 1;
    };
  };

  logging = {
    Serilog = {
      MinimumLevel = {
        Default = "Information";
        Override = {
          Microsoft = "Warning";
          System = "Warning";
        };
      };
      WriteTo = [
        {
          Name = "Console";
          Args = {
            outputTemplate = "[{Timestamp:HH:mm:ss}] [{Level:u3}] [{ThreadId}] {SourceContext}: {Message:lj}{NewLine}{Exception}";
          };
        }
        {
          Name = "Async";
          Args = {
            configure = [
              {
                Name = "File";
                Args = {
                  path = "%JELLYFIN_LOG_DIR%//log_.log";
                  rollingInterval = "Day";
                  retainedFileCountLimit = 3;
                  rollOnFileSizeLimit = true;
                  fileSizeLimitBytes = 100000000;
                  outputTemplate = "[{Timestamp:yyyy-MM-dd HH:mm:ss.fff zzz}] [{Level:u3}] [{ThreadId}] {SourceContext}: {Message}{NewLine}{Exception}";
                };
              }
            ];
          };
        }
      ];
      Enrich = [
        "FromLogContext"
        "WithThreadId"
      ];
    };
  };

  defaultTemplateValues = {
    owner = cfg.jellyfin.user;
    group = cfg.group;
    mode = "0660";
    restartUnits = [ "jellyfin.service" ];
  };

  makeXmlTemplate =
    {
      rootName,
      attrs,
      name,
    }:
    {
      "jellyfin-${name}.xml" = {
        content = cluster.lib.generators.toXML { inherit rootName; } attrs;
        # Templates must link to the configuration directory, as the service does not permit a link farm destination to be used as the configuration directory.
        path = "${config.services.jellyfin.configDir}/${name}.xml";
      } // defaultTemplateValues;
    };

  makeJsonTemplate =
    {
      attrs,
      name,
    }:
    {
      "jellyfin-${name}.json" = {
        path = "${config.services.jellyfin.configDir}/${name}.json";
        # Templates must link to the configuration directory, as the service does not permit a link farm destination to be used as the configuration directory.
        content = lib.generators.toJSON { } attrs;
      } // defaultTemplateValues;
    };
in
{
  config = lib.mkIf (cfg.enable && cfg.jellyfin.enable) {
    sops.templates = lib.mkMerge [
      (makeXmlTemplate {
        rootName = "BrandingOptions";
        attrs = branding;
        name = "branding";
      })

      (makeXmlTemplate {
        rootName = "EncodingOptions";
        attrs = encoding;
        name = "encoding";
      })

      (makeXmlTemplate {
        rootName = "MigrationOptions";
        attrs = migrations;
        name = "migrations";
      })

      (makeXmlTemplate {
        rootName = "NetworkConfiguration";
        attrs = network;
        name = "network";
      })

      (makeXmlTemplate {
        rootName = "ServerConfiguration";
        attrs = system;
        name = "system";
      })

      (makeJsonTemplate {
        attrs = logging;
        name = "logging.default";
      })
    ];
  };
}
