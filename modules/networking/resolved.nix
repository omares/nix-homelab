{
  ...
}:
{
  services.resolved = {
    enable = true;
    settings.Resolve = {
      DNSSEC = false;
      DNSStubListener = false;
    };
  };
}
