{
  imports = [
    ../../services/resolved.nix
    ../../services/adguard-home.nix
  ];

  networking.firewall = {
    allowedTCPPorts = [
      53 # DNS over TCP
      853 # DNS over TLS (DoT)
      784 # DNS over QUIC (DoQ)
      443 # DNS over HTTPS (DoH)
    ];
    allowedUDPPorts = [
      53 # DNS over UDP (standard DNS)
      784 # DNS over QUIC (DoQ)
    ];
  };

  sops-vault.items = [ "adguard-home" ];
}
