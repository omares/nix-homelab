{ inputs, ... }:
{
  imports = [
    inputs.sops-nix.nixosModules.sops
    inputs.nix-sops-vault.nixosModules.sops-vault
    ../../storage/truenas.nix
    ./options.nix
    ./prowlarr.nix
    ./radarr.nix
    ./sabnzbd
    ./sonarr.nix
    ./sops.nix
    ./users.nix
  ];
}
