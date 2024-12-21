{
  lib,
  ...
}:
{
  imports = [
    # ../../security/sops.nix
    ../../security/acme.nix
  ];

  services.nginx = {
    enable = true;
    recommendedTlsSettings = true;
    recommendedOptimisation = true;
    recommendedBrotliSettings = true;
    recommendedGzipSettings = true;
    recommendedProxySettings = true;

  };

  services.nginx.virtualHosts =
    let
      mkVhost = domain: ip: {
        enableACME = true;
        forceSSL = true;
        acmeRoot = null;
        locations."/" = {
          proxyPass = ip;
          extraConfig =
            # required when the target is also TLS server with multiple hosts
            "proxy_ssl_server_name on;"
            +
              # required when the server wants to use HTTP Authentication
              "proxy_pass_header Authorization;";
        };
      };
    in
    lib.mapAttrs mkVhost {
      "truenas.mares.id" = "http://https://192.168.20.114";
      "pve01.mares.id" = "http://192.168.20.246";
    };

  # sops-vault = [
  #   "acme"
  #   "easydns"
  # ];
}
