{
  config,
  ...
}:
{
  sops.templates."acme-email".content = ''"${config.sops.placeholder.acme_email}"'';

  security.acme = {
    acceptTerms = true;
    defaults = {
      server = "https://acme-staging-v02.api.letsencrypt.org/directory";
      email = config.sops.templates."acme-email".path;
      dnsProvider = "easydns";
      credentialFiles = {
        "EASYDNS_KEY_FILE" = config.sops.secrets.easydns_key.path;
        "EASYDNS_TOKEN_FILE" = config.sops.secrets.easydns_token.path;
      };
    };
  };
}
