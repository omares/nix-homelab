{
  inputs,
  config,
  lib,
  ...
}:
{
  imports = [
    inputs.sops-nix.nixosModules.sops
    inputs.nix-sops-vault.nixosModules.sops-vault
    ../../users/starr.nix
    # ../../users/sabnzbd.nix
    ../../services/sabnzbd
    ../../storage/truenas.nix
  ];

  homelab.storage.truenas.media = {
    enable = true;
    uid = config.ids.uids.sabnzbd;
  };

  sops-vault.items = [
    "starr"
  ];
}
