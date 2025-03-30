{
  config,
  lib,
  ...
}:
let
  cfg = config.mares.networking.acme;
in
{
  options.mares.networking.acme = {
    enable = lib.mkEnableOption "Enable ACME certificate management.";
  };

  config = lib.mkIf cfg.enable {
    security.acme = {
      acceptTerms = true;
      defaults = {
        # Remove comment to use acme staging server for testing purposes
        # server = "https://acme-staging-v02.api.letsencrypt.org/directory";
        email = "letsencrypt.mslk1@mres.me";
        dnsProvider = "easydns";
        credentialFiles = {
          "EASYDNS_KEY_FILE" = config.sops.secrets.easydns_key.path;
          "EASYDNS_TOKEN_FILE" = config.sops.secrets.easydns_token.path;
        };
      };
    };
  };
}
