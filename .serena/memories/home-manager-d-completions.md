# Home Manager Configuration for d command completions

## Plugin Approach (Recommended for personal use)

```nix
{ config, pkgs, ... }:
let
  nixProxmoxPath = "/Users/ota/development/omares/nix-proxmox";
  
  d-completions = pkgs.runCommand "d-completions" {} ''
    mkdir -p $out/share/zsh/site-functions
    ${nixProxmoxPath}/bin/d --completion > $out/share/zsh/site-functions/_d
  '';
in
{
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    
    plugins = [
      {
        name = "d-completions";
        src = d-completions;
        completions = [ "share/zsh/site-functions" ];
      }
    ];
  };
}
```

## Alternative: home.file approach (Most compatible)

```nix
{ config, pkgs, ... }:
let
  nixProxmoxPath = "/Users/ota/development/omares/nix-proxmox";
in
{
  home.file.".zsh/completions/_d".source = pkgs.runCommand "d-completion" {} ''
    ${nixProxmoxPath}/bin/d --completion > $out
  '';

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    initExtra = ''
      fpath+=${config.home.homeDirectory}/.zsh/completions
    '';
  };
}
```

## Alternative: siteFunctions (Inline)

```nix
{ config, pkgs, ... }:
let
  nixProxmoxPath = "/Users/ota/development/omares/nix-proxmox";
in
{
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    
    siteFunctions = {
      "_d" = builtins.readFile (pkgs.runCommand "d-completion" {} ''
        ${nixProxmoxPath}/bin/d --completion > $out
      '');
    };
  };
}
```
