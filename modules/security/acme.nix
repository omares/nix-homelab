{
  config,
  ...
}:
{
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
}
