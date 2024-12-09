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
