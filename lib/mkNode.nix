{ lib }:
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
  rolesExcludingDefault = builtins.filter (role: role != lib.roles.default) roles;
in
#assert builtins.trace "Builder role args: ${toString (builtins.attrNames args)}" true;
#assert builtins.trace "Builder role lib source: ${toString lib.outPath or "unknown"}" true;
#assert builtins.trace "Builder role pkgs: ${toString pkgs.system}" true;
#assert builtins.trace "mkNode called with roles: ${toString roles}" true;
{
  deployment = deployment // {
    tags = (deployment.tags or [ ]) ++ rolesExcludingDefault;
  };

  networking = lib.mkIf (name != "default") {
    hostName = name;
  };

  imports =
    assert builtins.trace "Before mapping roles in mkNode" true;
    map (
      role:
      assert builtins.trace "Processing role: ${role}" true;
      ../roles/${role}
    ) roles
    ++ imports;
}
// (removeAttrs args [
  "roles"
  "deployment"
  "imports"
])
