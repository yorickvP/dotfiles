{
  pkgs,
  ...
}:
{
  # todo: use upstream programs.ghostty
  home.sessionVariables.TERMINAL = "ghostty";
  home.packages = [ pkgs.ghostty ];
  xdg.configFile."ghostty/config".text = ''
    font-family = "DejaVuSansM Nerd Font"
    font-size = 12
    background-opacity = 0.95
    theme = dark:Catppuccin Mocha,light:Catppuccin Latte
    gtk-single-instance = true
    window-decoration = false
    adjust-cursor-thickness = 3
    minimum-contrast = 1.5
    keybind = alt+one=unbind
    keybind = alt+two=unbind
    keybind = alt+three=unbind
    keybind = alt+four=unbind
    keybind = alt+five=unbind
    keybind = alt+six=unbind
    keybind = alt+seven=unbind
    keybind = alt+eight=unbind
    keybind = alt+nine=unbind
    keybind = alt+zero=unbind
    keybind = ctrl+backspace=text:\x1B\x7F
    keybind = shift+enter=text:\x1b\r
    window-inherit-working-directory = false
    selection-word-chars = ` \t'"│`|:;,()[]{}<>$⏎«»=`
  '';
}
