{ nixpkgs, homelabLib, ... }:
{
  meta = {
    nixpkgs = import nixpkgs {
      system = "x86_64-linux";
    };

    specialArgs = {
      inherit homelabLib;
    };
  };

  defaults = homelabLib.mkNode {
    roles = [ homelabLib.roles.defaults ];
    deployment = {
      targetUser = "omares";
    };
  };

  build-01 = homelabLib.mkNode {
    roles = [
      homelabLib.roles.builder
    ];

    deployment = {
      targetHost = "192.168.20.224";
    };
  };

  build-02 = homelabLib.mkNode {
    nixpkgs.system = "aarch64-linux";

    roles = [
      homelabLib.roles.builder
    ];

    deployment = {
      targetHost = "192.168.20.46";
    };
  };

  dns-01 = homelabLib.mkNode {
    roles = [
      homelabLib.roles.dns
    ];
    deployment = {
      targetHost = "192.168.20.47";
    };
  };

  dns-02 = homelabLib.mkNode {
    nixpkgs.system = "aarch64-linux";

    roles = [
      homelabLib.roles.dns
    ];
    deployment = {
      targetHost = "192.168.20.xx";
    };
  };
}
