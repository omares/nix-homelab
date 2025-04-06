{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.mares.services.scrypted;

  python312Packages =
    python-pkgs: with python-pkgs; [
      pip
      setuptools
      wheel
      debugpy
      gst-python
    ];

  python312 = pkgs.python312.withPackages python312Packages;

  # Python 3.9 is primarily used for TensorFlow, as the latest wheels package from Google only supports version 3.9.
  # This unfortunately is not compatible with Nix, as the Nix ecosystem has transitioned to newer package versions.
  # See comment below for potential solution and further challenges.
  # The Python 3.9 executable is provided to have it available, but I do not expect it to do anything.
  # python39Packages =
  #   python-pkgs: with python-pkgs; [
  #     pip
  #     debugpy

  #     # The versions provided from current nixpkgs installations are too new, not matching the expected versions.
  #     # tensorflow
  #     # numpy
  #   ];

  # python39 = pkgs.python39.withPackages python39Packages;

  /*
    nixpkgs 22.11 allows building Python 3.9 with TensorFlow without needing to override all dependent python packages.
    Providing the gcc-unwrapped.lib through LD_LIBRARY_PATH from 22.11 resolves NumPy's 1.x expectation of GLIBC_2.38.
        " ImportError: /nix/store/vnwdak3n1w2jjil119j65k8mw1z23p84-glibc-2.35-224/lib/libc.so.6: version `GLIBC_2.38' not found
        (required by /nix/store/bpq1s72cw9qb2fs8mnmlw6hn2c7iy0ss-gcc-14-20241116-lib/lib/libgomp.so.1)"

    But even after resolving the Python 3.9 issue with the matching packages, libedgetpu will remain unusable because it
    is built against a newer GCC version (expecting GLIBC_3.xx). I could not find a solution to this, making it impossible
    to use TensorFlow detection.

    This is what the potential solution looks like.

      nixpkgs-2211 = inputs.nixpkgs-2211.legacyPackages.${pkgs.system};

      python39' = nixpkgs-2211.python39.buildEnv.override {
        extraLibs = python39Packages nixpkgs-2211.python39.pkgs;
        makeWrapperArgs = [
          "--set LD_LIBRARY_PATH ${
            lib.makeLibraryPath [
              nixpkgs-2211.gcc-unwrapped.lib
              pkgs.tensorflow-lite
              pkgs.libedgetpu
            ]
          }"
        ];
      };
  */

  gstPlugins = with pkgs.gst_all_1; [
    gstreamer
    gst-plugins-base
    gst-plugins-good
    gst-plugins-bad
    gst-libav
    gst-vaapi
  ];
in
{
  options.mares.services.scrypted = {
    enable = lib.mkEnableOption "Scrypted home automation server";

    package = lib.mkPackageOption pkgs "scrypted" { };

    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Open ports 11080 and 10443 in the firewall";
    };

    installPath = lib.mkOption {
      type = lib.types.path;
      default = "/var/lib/scrypted";
      description = "Directory where scrypted data will be stored";
    };

    user = lib.mkOption {
      type = lib.types.str;
      default = "scrypted";
      description = "User account under which scrypted runs";
    };

    group = lib.mkOption {
      type = lib.types.str;
      default = "scrypted";
      description = "Group account under which scrypted runs";
    };

    environmentFiles = lib.mkOption {
      type = lib.types.listOf lib.types.path;
      default = [ ];
      description = "Environment files to pass to service.";
      example = [
        /path/to/.env
        /path/to/.env.secret
      ];
    };

    extraEnvironment = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
      description = "Additional environment variables for scrypted";
      example = {
        SCRYPTED_NVR_VOLUME = "/var/lib/scrypted/nvr";
        SCRYPTED_SECURE_PORT = 443;
        SCRYPTED_INSECURE_PORT = 8080;
      };
    };
  };

  config = lib.mkIf cfg.enable {

    environment.systemPackages = [
      python312
      pkgs.ffmpeg
      pkgs.gcc-unwrapped.lib
      pkgs.gobject-introspection
      # pkgs.tensorflow-lite
    ] ++ gstPlugins;

    systemd.services.scrypted = {
      description = "Scrypted home automation server";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      environment = lib.mkMerge [
        {
          SCRYPTED_CAN_RESTART = "true";
          SCRYPTED_INSTALL_PATH = cfg.installPath;
          SCRYPTED_VOLUME = "${cfg.installPath}/volume";
          SCRYPTED_PYTHON_PATH = "${lib.getExe python312}";
          SCRYPTED_PYTHON39_PATH = "${lib.getExe python312}";
          SCRYPTED_PYTHON312_PATH = "${lib.getExe python312}";
          SCRYPTED_FFMPEG_PATH = "${lib.getExe pkgs.ffmpeg}";

          LD_LIBRARY_PATH = lib.makeLibraryPath [
            pkgs.gcc-unwrapped.lib
            pkgs.ocl-icd
            pkgs.intel-compute-runtime-legacy1
            pkgs.intel-media-driver # For VA-API hardware acceleration
            pkgs.intel-media-sdk # For QuickSync
            pkgs.libva # For VA-API general support
            pkgs.intel-vaapi-driver # VA-API backend
            # pkgs.tensorflow-lite
            pkgs.ffmpeg
            pkgs.gobject-introspection
            pkgs.libdrm
          ];

          GST_PLUGIN_PATH = lib.makeSearchPath "lib/gstreamer-1.0" gstPlugins;
        }
        cfg.extraEnvironment
      ];

      path = [
        python312
        pkgs.ffmpeg
        pkgs.gcc-unwrapped.lib
        pkgs.gobject-introspection
      ] ++ gstPlugins;

      serviceConfig = {
        ExecStart = "${lib.getExe cfg.package}";
        Restart = "always";
        RestartSec = "3";

        User = cfg.user;
        Group = cfg.group;

        StateDirectory = "scrypted";
        StateDirectoryMode = "0750";

        ProtectSystem = "strict";
        ProtectHome = true;
        WorkingDirectory = cfg.installPath;
        ReadWritePaths = [ cfg.installPath ];
        PrivateDevices = false;
        PrivateTmp = true;
        NoNewPrivileges = true;
        RestrictRealtime = true;

        RestrictAddressFamilies = [
          "AF_INET"
          "AF_INET6"
          "AF_NETLINK"
        ];

        EnvironmentFile = cfg.environmentFiles;
      };
    };

    users.users = lib.mkIf (cfg.user == "scrypted") {
      ${cfg.user} = {
        isSystemUser = true;
        group = cfg.group;
        home = cfg.installPath;
        createHome = true;
        description = "Scrypted service user";
      };
    };

    users.groups = lib.mkIf (cfg.group == "scrypted") { ${cfg.group} = { }; };

    networking.firewall = lib.mkIf cfg.openFirewall {
      allowedTCPPorts = [
        11080
        10443
      ];
    };
  };
}
