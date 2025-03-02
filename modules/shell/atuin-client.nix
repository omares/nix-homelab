{
  config,
  ...
}:
let
  owner = "omares";
in
{
  imports = [
    ../services/atuin-client.nix
  ];

  sops-vault.items = [ "atuin" ];

  sops.secrets = {
    atuin_password = {
      owner = owner;
    };
    atuin_key = {
      owner = owner;
    };
  };

  services.atuin-client = {
    enable = true;
    passwordPath = config.sops.secrets.atuin_password.path;
    keyPath = config.sops.secrets.atuin_key.path;
    username = owner;
    owner = owner;
    settings = {
      sync_address = "https://atuin.mares.id";
      style = "compact";
      filter_mode = "host";
    };
  };
}
