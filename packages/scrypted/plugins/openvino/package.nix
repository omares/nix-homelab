{
  lib,
  stdenv,
  fetchurl,
  python312,
  autoPatchelfHook,
  level-zero,
  ocl-icd,
  unzip,
  zlib,
  mkScryptedPlugin,
}:
let
  versions = import ./versions.nix;

  # From Scrypted server/src/plugin/runtime/python-worker.ts
  scryptedPythonVersion = "20240317";
  pythonMajorMinor = "3.12";

  # nixpkgs' numpy is too new for openvino, and overriding it in the package set rebuilds
  # everything depending on it from source. Use the PyPI wheels pip would install instead.
  mkWheel =
    pname: buildInputs:
    python312.pkgs.buildPythonPackage {
      inherit pname buildInputs;
      inherit (versions.wheels.${pname}) version;
      format = "wheel";
      src = fetchurl { inherit (versions.wheels.${pname}) url hash; };
      nativeBuildInputs = [ autoPatchelfHook ];
      # Dependencies are listed flat in pythonEnv, like pip installs them
      dontCheckRuntimeDeps = true;
    };

  nativeLibs = [
    stdenv.cc.cc.lib
    zlib
  ];

  pythonEnv = python312.withPackages (
    ps:
    [
      (mkWheel "numpy" nativeLibs)
      (mkWheel "openvino" (
        nativeLibs
        ++ [
          level-zero
          ocl-icd
        ]
      ))
      (mkWheel "openvino-telemetry" [ ])
      (mkWheel "opencv-python-headless" nativeLibs)
      (mkWheel "transformers" [ ])
      (mkWheel "huggingface-hub" [ ])
      (mkWheel "tokenizers" nativeLibs)
      (mkWheel "safetensors" nativeLibs)
      (mkWheel "hf-xet" nativeLibs)
    ]
    ++ (with ps; [
      click
      filelock
      fsspec
      httpx
      packaging
      pillow
      pyyaml
      regex
      tqdm
      typer
      typing-extensions
      ptpython
      wheel
    ])
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

    ${pythonEnv.interpreter} -c "
    import numpy, openvino, cv2, PIL
    from transformers import CLIPProcessor
    assert numpy.__version__ == '${versions.wheels.numpy.version}', numpy.__version__
    "

    # Extract requirements.txt from plugin.zip for marker files
    ${unzip}/bin/unzip -p $out/plugin.zip requirements.txt > $out/python-env/requirements.txt
    cp $out/python-env/requirements.txt $out/python-env/requirements.installed.txt

    printf 'ptpython\nwheel' > $out/python-env/requirements.scrypted.txt
    cp $out/python-env/requirements.scrypted.txt $out/python-env/requirements.scrypted.installed.txt
  '';

  passthru = finalAttrs: {
    inherit
      pythonMajorMinor
      scryptedPythonVersion
      pythonEnv
      ;
    updateScript = ./update.sh;

    provision = {
      warnings = [ "scrypted-openvino: Requires internet access to download ML models on first use" ];
      symlinks = [
        {
          target = "python${pythonMajorMinor}-Linux-x86_64-${scryptedPythonVersion}";
          path = "${finalAttrs.finalPackage}/python-env";
        }
      ];
    };
  };

  meta = {
    description = "Scrypted OpenVINO plugin with pre-provisioned Python environment";
    homepage = "https://github.com/koush/scrypted";
    license = lib.licenses.mit;
    platforms = [ "x86_64-linux" ];
  };
}
