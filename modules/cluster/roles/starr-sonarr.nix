{
  inputs,
  ...
}:
{
  imports = [
    inputs.sops-nix.nixosModules.sops
    inputs.nix-sops-vault.nixosModules.sops-vault
    ../../users/starr.nix
    ../../services/starr/sonarr.nix
  ];

  # https://github.com/NixOS/nixpkgs/issues/360592
  # https://github.com/Sonarr/Sonarr/pull/7443
  nixpkgs.config.permittedInsecurePackages = [
    "aspnetcore-runtime-6.0.36"
    "aspnetcore-runtime-wrapped-6.0.36"
    "dotnet-sdk-6.0.428"
    "dotnet-sdk-wrapped-6.0.428"
  ];

  sops-vault.items = [
    "starr"
    "pgsql"
  ];
}
