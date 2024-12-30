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

  cluster.storage.truenas.media = {
    enable = true;
  };

  sops-vault.items = [
    "starr"
  ];

  systemd.services.sabnzbd = {
    wants = [
      "sops-nix.service"
      "mnt-media.mount"
    ];
    after = [
      "sops-nix.service"
      "mnt-media.mount"
    ];
  };
}
