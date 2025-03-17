{
  ...
}:

{
  imports = [
    ../modules/shell/atuin-server.nix
  ];

  sops-vault.items = [ "pgsql" ];

  mares.shell.atuin-server = {
    enable = true;
  };
}
