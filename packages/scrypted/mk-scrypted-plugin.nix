# Generic builder for Scrypted plugins
# Output contains package.json and plugin.zip for sideload API
{
  lib,
  stdenvNoCC,
  fetchurl,
}:

{
  pname,
  version,
  hash,
  meta ? { },
  passthru ? { },
  postInstall ? "",
  ...
}@args:

stdenvNoCC.mkDerivation (
  {
    pname = "scrypted-plugin-${pname}";
    inherit version;

    src = fetchurl {
      url = "https://registry.npmjs.org/@scrypted/${pname}/-/${pname}-${version}.tgz";
      inherit hash;
    };

    dontUnpack = true;

    installPhase = ''
      runHook preInstall

      mkdir -p $out
      tar -xzf $src --strip-components=1 -C $out package/package.json
      tar -xzf $src --strip-components=2 -C $out package/dist/plugin.zip

      runHook postInstall
    '';

    inherit postInstall;

    passthru = {
      pluginName = "@scrypted/${pname}";
      inherit version;
    }
    // passthru;

    meta = {
      homepage = "https://www.npmjs.com/package/@scrypted/${pname}";
      # License varies per plugin - see https://github.com/koush/scrypted/blob/main/LICENSE.md
      platforms = lib.platforms.linux;
    }
    // meta;
  }
  // removeAttrs args [
    "pname"
    "version"
    "hash"
    "meta"
    "passthru"
    "postInstall"
  ]
)
