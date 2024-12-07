{
  name,
  config,
  lib,
  ...
}:
{
  services.resolved = {
    enable = true;
    dnssec = "false";
    extraConfig = ''
      DNSStubListener=no
    '';
  };
}
