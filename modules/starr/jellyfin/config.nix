{
  pkgs,
  config,
  lib,
  mares,
  ...
}:
let
  cfg = config.mares.starr;

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
    EnableDecodingColorDepth10Vp9 = true;
    EnableDecodingColorDepth10HevcRext = false;
    EnableDecodingColorDepth12HevcRext = false;
    EnableEnhancedNvdecDecoder = false;
    PreferSystemNativeHwDecoder = true;
    EnableIntelLowPowerH264HwEncoder = false; # not available in virtualized environment
    EnableIntelLowPowerHevcHwEncoder = false; # not available in virtualized environment
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
    ];
    AllowOnDemandMetadataBasedKeyframeExtractionForExtensions = [
      { string = "mkv"; }
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
        content = mares.infrastructure.lib.generators.toXML { inherit rootName; } attrs;
        # Templates must link to the configuration directory, as the service does not permit a link farm destination to be used as the configuration directory.
        path = "${config.services.jellyfin.configDir}/${name}.xml";
      }
      // defaultTemplateValues;
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
      }
      // defaultTemplateValues;
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
