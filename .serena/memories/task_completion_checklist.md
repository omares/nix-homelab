# Task Completion Checklist

## When a Task is Completed

### 1. Code Formatting
Always run the formatter before committing:
```bash
nix fmt
```

### 2. Validation
Check that the flake is valid and passes all checks (including formatting):
```bash
nix flake check
```

### 3. Build Verification
If modifying a configuration, build it to verify:
```bash
nix build .#nixosConfigurations.<hostname>.config.system.build.toplevel
```

### 4. Module Guidelines Check
- [ ] Module follows the standard structure (default.nix, options.nix, service.nix)
- [ ] Options use proper types and have descriptions
- [ ] Conditional logic uses `mkIf` appropriately
- [ ] File naming follows kebab-case convention
- [ ] Option naming follows camelCase convention
- [ ] Secrets are declared in the role (`sops-vault.items`) and passed to the module as `*File` options

### 5. Documentation
- [ ] Comments explain why, not what
- [ ] New options have clear descriptions
- [ ] Breaking changes are noted in `docs/`

### 6. Testing Considerations
- For service changes, consider impact on dependent services
- For Proxmox VM changes, test deployment with `--dry-run` first
- For secrets/sops changes, verify encryption/decryption works

### 7. Commit Guidelines
- Concise conventional commit messages (`feat(hass): ...`, `fix(mqtt): ...`)
- Reference related tickets where possible
- Group related changes logically
