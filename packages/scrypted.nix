{
  lib,
  stdenv,
  buildNpmPackage,
  fetchFromGitHub,
  nodejs_22,
  jq,
  moreutils,
  writers,
  nix-update-script,
  python312,
  ffmpeg,
  bashInteractive,
  gcc-unwrapped,
  zlib,
  libdrm,
  libva,
}:
let
  nodejs = nodejs_22;
  python = python312.withPackages (
    ps: with ps; [
      pip
      setuptools
      wheel
      debugpy
    ]
  );
in
(buildNpmPackage.override { inherit nodejs; }) rec {
  pname = "scrypted";
  version = "0.143.0";

  src = fetchFromGitHub {
    owner = "koush";
    repo = "${pname}";
    rev = "v${version}";
    hash = "sha256-5fFyrphAHSAJYfcw5lg7X7zaLt4SXIHQL/3SEPcStiY=";
  };

  npmDepsHash = "sha256-pKigplSr+3PVT4Y25Cc1QwOtrjMO7Gki23V9GXBntoM=";

  sourceRoot = "${src.name}/server";

  nativeBuildInputs = [
    nodejs
    jq
    moreutils
  ];

  # Replace @scrypted/node-pty (broken build) with official node-pty.
  # The vendored package-lock.json must be updated when upgrading scrypted:
  #   1. Download new package-lock.json from upstream
  #   2. Remove @scrypted/node-pty, add node-pty and node-addon-api
  #   3. Update npmDepsHash
  postPatch = ''
    ${lib.getExe jq} --sort-keys \
      'del(.dependencies["@scrypted/node-pty"]) | .dependencies["node-pty"] |= "1.1.0"' \
      package.json \
      | ${lib.getExe' moreutils "sponge"} package.json

    cp ${./package-lock.json} package-lock.json
  '';

  # Skip postinstall scripts - they try to download Python (@scrypted/server)
  # and ffmpeg (@scrypted/ffmpeg-static) binaries which fails in the sandbox.
  # We provide these via makeWrapperArgs instead.
  npmInstallFlags = [ "--ignore-scripts" ];
  npmRebuildFlags = [ "--ignore-scripts" ];
  npmBuildScript = "build";

  env = {
    SCRYPTED_PYTHON_PATH = lib.getExe python;
    SCRYPTED_PYTHON312_PATH = lib.getExe python;
    SCRYPTED_FFMPEG_PATH = lib.getExe ffmpeg;
    SHELL = lib.getExe bashInteractive;
  };

  makeWrapperArgs =
    let
      # Runtime libraries required by scrypted and its plugins:
      #
      # gcc-unwrapped.lib (libstdc++)
      #   Required by pip-installed Python packages like numpy and openvino.
      #   These packages are compiled against libstdc++ and need it at runtime.
      #
      # zlib
      #   Compression library required by numpy and other Python packages.
      #
      # libdrm (Linux only)
      #   Direct Rendering Manager library for GPU access.
      #   Required by @scrypted/nvr's libav addon for hardware-accelerated video decoding.
      #
      # libva (Linux only)
      #   Video Acceleration API library for hardware video encode/decode.
      #   Required by @scrypted/nvr's libav addon for VA-API hardware acceleration.
      runtimeLibs =
        [ gcc-unwrapped.lib zlib ]
        ++ lib.optionals stdenv.hostPlatform.isLinux [
          libdrm
          libva
        ];
    in
    [
      "--set NODE_ENV production"
      "--set SCRYPTED_PYTHON_PATH ${lib.getExe python}"
      "--set SCRYPTED_PYTHON312_PATH ${lib.getExe python}"
      "--set SCRYPTED_FFMPEG_PATH ${lib.getExe ffmpeg}"
      "--set SHELL ${lib.getExe bashInteractive}"
      "--prefix PATH : ${lib.makeBinPath [ ffmpeg python ]}"
      "--prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath runtimeLibs}"
      # Intel OpenCL/OpenGL libraries for GPU acceleration.
      # This path is populated by hardware.graphics.extraPackages (e.g., intel-compute-runtime).
      "--prefix LD_LIBRARY_PATH : /run/opengl-driver/lib"
    ];

  postInstall = ''
    cp ${writers.writeJSON "install.json" { inherit version; }} $out/install.json
  '';

  passthru.updateScript = nix-update-script { };

  meta = {
    description = ''
      Scrypted is a high performance home video integration platform and NVR with smart detections.
    '';
    mainProgram = "scrypted-serve";
    homepage = "https://github.com/koush/scrypted";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
  };
}
