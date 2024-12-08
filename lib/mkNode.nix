{ mkIf, availableRoles }:
{
  roles ? [ ],
  deployment ? { },
  imports ? [ ],
  ...
}@args:
{
  name,
  pkgs,
  modulesPath,
  ...
}:
let
  rolesExcludingDefaults = builtins.filter (role: role != availableRoles.defaults) roles;
in
#assert builtins.trace "Builder role args: ${toString (builtins.attrNames args)}" true;
#assert builtins.trace "Builder role lib source: ${toString lib.outPath or "unknown"}" true;
#assert builtins.trace "Builder role pkgs: ${toString pkgs.system}" true;
#assert builtins.trace "mkNode called with roles: ${toString roles}" true;
{
  deployment = deployment // {
    tags = (deployment.tags or [ ]) ++ rolesExcludingDefaults;
  };

  networking = mkIf (name != "default") {
    hostName = name;
  };

  imports = map (role: ../roles/${role}) roles ++ imports;
}
// (removeAttrs args [
  "roles"
  "deployment"
  "imports"
])
