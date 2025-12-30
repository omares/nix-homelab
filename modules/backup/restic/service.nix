{
  lib,
  config,
  pkgs,
  mares,
  ...
}:
let
  cfg = config.mares.backup.restic;
  truenasFqdn = mares.infrastructure.nodes.truenas.dns.fqdn;
in
{
  config = lib.mkIf cfg.enable {
    mares.users.restic.enable = true;

    security.wrappers.restic = {
      source = lib.getExe pkgs.restic;
      owner = "restic";
      group = "restic";
      permissions = "500";
      capabilities = "cap_dac_read_search+ep";
    };

    programs.ssh.extraConfig = ''
      Host truenas-backup
        Hostname ${truenasFqdn}
        User restic
        IdentityFile ${cfg.sshKeyFile}
        StrictHostKeyChecking accept-new
        ServerAliveInterval 60
        ServerAliveCountMax 240
    '';

    programs.ssh.knownHosts."${truenasFqdn}" = {
      publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHD/wTi37v0qBLKUZq3oZxAdE9Ikh9nfivOTi0k0R7XE";
    };

    services.restic.backups = lib.mapAttrs (name: job: {
      user = "restic";
      package = pkgs.writeShellScriptBin "restic" ''
        exec /run/wrappers/bin/restic "$@"
      '';
      repository = "sftp:truenas-backup:${job.repoPath}";
      passwordFile = job.passwordFile;
      paths = job.paths;
      exclude = job.exclude;
      timerConfig = job.timerConfig;
      pruneOpts = job.pruneOpts;
      extraBackupArgs = job.extraBackupArgs;
      backupPrepareCommand = job.backupPrepareCommand;
      backupCleanupCommand = job.backupCleanupCommand;
      initialize = true;
      createWrapper = true;
    }) cfg.jobs;
  };
}
