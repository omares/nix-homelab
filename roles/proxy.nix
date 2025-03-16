{
  inputs,
  ...
}:

{
  imports = [
    inputs.sops-nix.nixosModules.sops
    inputs.nix-sops-vault.nixosModules.sops-vault
    ../modules/security/acme.nix
    ../modules/networking/proxy-nginx.nix
  ];
  config = {
    networking.firewall = {
      allowedTCPPorts = [
        80
        443
      ];
    };

    sops-vault.items = [
      "easydns"
    ];

    mares.networking.proxy-nginx = {
      enable = true;
    };
  };
}
