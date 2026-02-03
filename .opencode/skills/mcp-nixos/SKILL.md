---
name: mcp-nixos
description: Model Context Protocol resources and tools for NixOS, Home Manager, and nix-darwin
license: MIT
compatibility: opencode
metadata:
  audience: nix-developers
  workflow: nix-configuration
---

## What I do

- Search NixOS packages, options, and programs with accurate, real-time data
- Query Home Manager options for user environment configuration
- Explore nix-darwin options for macOS system settings
- Find Nixvim Neovim configuration options
- Search FlakeHub and community flakes for reusable modules
- Look up Nix function signatures and documentation via Noogle
- Access NixOS Wiki articles and official documentation
- Get package version history with nixpkgs commit hashes
- Check binary cache status for packages
- Browse local flake inputs directly from the Nix store

## When to use me

Use me when you need to:
- **Find correct package names**: Avoid hallucinating package names in Nix expressions
- **Look up configuration options**: Find the exact option path and type for NixOS/Home Manager/nix-darwin
- **Explore flakes**: Discover community flakes or browse FlakeHub
- **Write Nix code**: Find function signatures and documentation from Noogle
- **Troubleshoot issues**: Search Wiki articles and official docs
- **Pin specific versions**: Get historical package versions with commit hashes
- **Check availability**: Verify packages are in binary cache for faster builds
- **Browse flake structure**: Explore inputs without leaving your editor

## Workflow

### Finding Packages and Options
1. Search for packages: `nix(action="search", query="firefox", source="nixos", type="packages")`
2. Get detailed info: `nix(action="info", query="firefox", source="nixos", type="package")`
3. Search Home Manager options: `nix(action="search", query="git", source="home-manager")`
4. Browse options by prefix: `nix(action="options", source="darwin", query="system.defaults")`

### Working with Flakes
1. Search FlakeHub: `nix(action="search", query="nixpkgs", source="flakehub")`
2. List local inputs: `nix(action="flake-inputs", type="list")`
3. Browse flake files: `nix(action="flake-inputs", type="ls", query="nixpkgs:pkgs/by-name")`
4. Read flake source: `nix(action="flake-inputs", type="read", query="nixpkgs:flake.nix")`

### Getting Version Info
1. List recent versions: `nix_versions(package="python", limit=5)`
2. Find specific version: `nix_versions(package="nodejs", version="20.0.0")`

### Checking Documentation
1. Search NixOS Wiki: `nix(action="search", query="nvidia", source="wiki")`
2. Read official docs: `nix(action="search", query="packaging tutorial", source="nix-dev")`
3. Find Nix functions: `nix(action="search", query="mapAttrs", source="noogle")`

## Available Sources

| Source | Use Case |
|--------|----------|
| `nixos` | NixOS packages, options, programs |
| `home-manager` | Home Manager user configuration |
| `darwin` | nix-darwin macOS settings |
| `flakes` | Community flakes (search.nixos.org) |
| `flakehub` | FlakeHub registry |
| `nixvim` | Nixvim Neovim configuration |
| `noogle` | Nix function documentation |
| `wiki` | NixOS Wiki articles |
| `nix-dev` | Official Nix documentation |
| `nixhub` | Package metadata and store paths |

## Best Practices

- Always verify package names before using in configurations
- Use `action="info"` to get full option details including type and default values
- Check `action="cache"` before building to see if binaries are available
- Use specific sources (home-manager, darwin) rather than generic nixos when applicable
- Pin exact versions using nix_versions when reproducibility matters
