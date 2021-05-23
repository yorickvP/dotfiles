#!/usr/bin/env bash
sed -i 's/colors:/colors-alt:/;t;s/colors-alt:/colors:/' ~/.config/alacritty/alacritty.yml
(grep -B1 '^colors:$' ~/.config/alacritty/alacritty.yml | head -n1 | grep -qi light && echo "light" || echo dark) | tee ~/dotfiles/color-scheme
#emacsclient -e "(set-solarized-theme nil '$(cat ~/dotfiles/color-scheme))" > /dev/null || true
if [ "$(cat ~/dotfiles/color-scheme)" = "dark" ]; then
    dconf write /org/gnome/desktop/interface/gtk-theme "'Adwaita-dark'"
    gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita-dark'
else
    dconf write /org/gnome/desktop/interface/gtk-theme "'Adwaita'"
    gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita'
fi
