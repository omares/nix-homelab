# Code Style and Conventions

## Nix Module Structure
- **Module Arguments**: Use `{ lib, config, pkgs, ... }:` pattern
- **Custom Library**: Access via `mares` argument for project-specific functions
- **No `with lib;`**: Reference functions explicitly (`lib.mkOption`, `lib.mkIf`)

## File Organization
- **Naming**:
  - Files: kebab-case (e.g., `adguard-home.nix`)
  - Options: camelCase (e.g., `bindAddress`, `listenPort`)
- **Module Split**:
  - `default.nix` - Module imports
  - `options.nix` - Option definitions
  - `service.nix` - Service implementation
  - `config.nix` - Configuration specifics

## Option Definitions
```nix
# Boolean options
enable = lib.mkEnableOption "Enable service description";

# Typed options with descriptions
bindAddress = lib.mkOption {
  type = lib.types.str;
  default = "127.0.0.1";
  description = "Address to bind the service to";
};
```

## Formatting Rules
- **Indentation**: 2 spaces (enforced by nixfmt via `nix fmt`)
- **Lists**: One item per line when long
- **Let Bindings**: Use `let ... in` for local variables

## Conditional Configuration
```nix
config = lib.mkIf config.mares.service.enable {
  # Conditional configuration here
};
```

## Import Patterns
```nix
{
  imports = [
    ./config.nix
    ./service.nix
  ];
}
```

## Error Handling
- Use assertions for critical checks
- Provide meaningful error messages
- Validate configuration at build time when possible
