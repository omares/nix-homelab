{
  lib,
  srcOnly,
  makeSetupHook,
  nodejs_20,
  jq,
  prefetch-npm-deps,
  diffutils,
}:

{
  customConfigHook = makeSetupHook {
    name = "custom-npm-config-hook";
    substitutions = {
      nodeSrc = nodejs_20;
      nodeGyp = "${nodejs_20}/lib/node_modules/npm/node_modules/node-gyp/bin/node-gyp.js";
      diff = "${diffutils}/bin/diff";
      jq = "${jq}/bin/jq";
      prefetchNpmDeps = "${prefetch-npm-deps}/bin/prefetch-npm-deps";
      nodeVersion = nodejs_20.version;
      nodeVersionMajor = lib.versions.major nodejs_20.version;
    };
  } ./npm-config-hook.sh;
}
