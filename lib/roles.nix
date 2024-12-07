let
  rolesList = builtins.attrNames (builtins.readDir ../roles);
in
builtins.listToAttrs (
  map (name: {
    inherit name;
    value = name;
  }) rolesList
)
