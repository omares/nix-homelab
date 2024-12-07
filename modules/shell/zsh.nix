{
  programs.zsh = {
    autosuggestions.enable = true;
    enable = true;
    enableBashCompletion = true;
    syntaxHighlighting.enable = true;

    interactiveShellInit = ''
      # Home/End
      bindkey "^[[H" beginning-of-line
      bindkey "^[[F" end-of-line

      # Ctrl + Arrow keys
      bindkey "^[[1;5C" forward-word
      bindkey "^[[1;5D" backward-word

      # Alternative bindings for Home/End
      bindkey "^[[7~" beginning-of-line
      bindkey "^[[8~" end-of-line

      # Add Ctrl+A and Ctrl+E bindings
      bindkey "^A" beginning-of-line
      bindkey "^E" end-of-line

      # Delete/Insert
      bindkey "^[[3~" delete-char
      bindkey "^[[2~" overwrite-mode

      # Alt + Arrow keys
      bindkey "^[[1;3C" forward-word
      bindkey "^[[1;3D" backward-word

    '';
  };
}
