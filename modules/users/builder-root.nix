{ pkgs, lib, ... }:
{

  # On Mac, the user connecting to the remote builder must exist as a user on the host machine.
  # Also the nix daemon runs as root, and this root user needs access to the system.
  # For convenience, it makes sense to use the root user to connect.
  # To ensure everything functions correctly, copy the appropriate private key to the root user's SSH directory at /var/root/.ssh.
  # Add the identity file in the config for use and verify that the SSH connection works for the root user.
  users.users = {
    root = {
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKM/Wfv6llweYoV2hLedBp9p6KRUkY7aPMF0zc6Uw8Fi"
      ];
    };
  };
}
