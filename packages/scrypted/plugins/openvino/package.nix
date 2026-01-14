{
  lib,
  stdenv,
  fetchPypi,
  python312,
  autoPatchelfHook,
  level-zero,
  ocl-icd,
  unzip,
  mkScryptedPlugin,
}:
let
  versions = import ./versions.nix;

  openvinoWheelVersion = "${versions.openvinoVersion}-${versions.openvinoWheelBuild}";

  # From Scrypted server/src/plugin/runtime/python-worker.ts
  scryptedPythonVersion = "20240317";
  pythonMajorMinor = "3.12";

  # Platform-specific configuration (merged wheel info + arch)
  platformInfo =
    {
      x86_64-linux = {
        arch = "x86_64";
        wheelPlatform = "manylinux2014_x86_64";
        hash = versions.openvinoHashes.x86_64-linux;
      };
      aarch64-linux = {
        arch = "aarch64";
        wheelPlatform = "manylinux_2_31_aarch64";
        hash = versions.openvinoHashes.aarch64-linux;
      };
    }
    .${stdenv.hostPlatform.system} or (throw "Unsupported platform: ${stdenv.hostPlatform.system}");

  openvino-telemetry = python312.pkgs.buildPythonPackage rec {
    pname = "openvino-telemetry";
    version = versions.openvinoTelemetryVersion;
    format = "wheel";

    src = fetchPypi {
      pname = "openvino_telemetry";
      inherit version;
      format = "wheel";
      dist = "py3";
      python = "py3";
      hash = versions.openvinoTelemetryHash;
    };

    meta = {
      description = "OpenVINO telemetry library";
      homepage = "https://github.com/openvinotoolkit/openvino";
      license = lib.licenses.asl20;
    };
  };

  openvino-2024 = python312.pkgs.buildPythonPackage rec {
    pname = "openvino";
    version = versions.openvinoVersion;
    format = "wheel";

    src = fetchPypi {
      inherit pname;
      version = openvinoWheelVersion;
      format = "wheel";
      python = "cp312";
      abi = "cp312";
      dist = "cp312";
      platform = platformInfo.wheelPlatform;
      hash = platformInfo.hash;
    };

    nativeBuildInputs = [ autoPatchelfHook ];
    buildInputs = [
      stdenv.cc.cc.lib
      level-zero
      ocl-icd
    ];

    dependencies = [
      python312.pkgs.numpy
      openvino-telemetry
      python312.pkgs.packaging
    ];

    pythonImportsCheck = [ "openvino" ];

    meta = {
      description = "OpenVINO toolkit for optimized deep learning inference";
      homepage = "https://github.com/openvinotoolkit/openvino";
      license = lib.licenses.asl20;
      platforms = [
        "x86_64-linux"
        "aarch64-linux"
      ];
    };
  };

  pythonEnv = python312.withPackages (
    ps: with ps; [
      openvino-2024
      pillow
      opencv4
      transformers
      huggingface-hub
      ptpython
      wheel
    ]
  );

in
mkScryptedPlugin {
  pname = "openvino";
  version = versions.version;
  hash = versions.hash;

  nativeBuildInputs = [ unzip ];

  postInstall = ''
    mkdir -p $out/python-env

    # Symlink Python site-packages
    for pkg in ${pythonEnv}/${pythonEnv.sitePackages}/*; do
      ln -s "$pkg" $out/python-env/
    done

    # Extract requirements.txt from plugin.zip for marker files
    ${unzip}/bin/unzip -p $out/plugin.zip requirements.txt > $out/python-env/requirements.txt
    cp $out/python-env/requirements.txt $out/python-env/requirements.installed.txt

    printf 'ptpython\nwheel' > $out/python-env/requirements.scrypted.txt
    cp $out/python-env/requirements.scrypted.txt $out/python-env/requirements.scrypted.installed.txt
  '';

  passthru = {
    inherit
      pythonMajorMinor
      scryptedPythonVersion
      pythonEnv
      ;
    platformArch = platformInfo.arch;
    updateScript = ./update.sh;
  };

  meta = {
    description = "Scrypted OpenVINO plugin with pre-provisioned Python environment";
    homepage = "https://github.com/koush/scrypted";
    license = lib.licenses.mit;
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
    ];
  };
}
