{
  imports = [
    # ../../security/sops.nix
    ../../services/resolved.nix
    ../../services/adguard-home.nix
  ];

  sops-vault.items = [ "adguard-home" ];
}
