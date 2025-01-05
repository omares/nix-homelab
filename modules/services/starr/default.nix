{ inputs, ... }:
{
  imports = [
    inputs.sops-nix.nixosModules.sops
    inputs.nix-sops-vault.nixosModules.sops-vault
    ../../storage/truenas.nix
    ./jellyfin
    ./options.nix
    ./prowlarr.nix
    ./radarr.nix
    ./recyclarr.nix
    ./sabnzbd
    ./sonarr.nix
    ./sops.nix
    ./users.nix
  ];
}
