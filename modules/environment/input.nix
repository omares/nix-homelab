{
  services.xserver = {
    enable = false;
    xkb = {
      layout = "us";
      variant = "symbolic";
    };
  };

  console = {
    useXkbConfig = true;
  };
}
