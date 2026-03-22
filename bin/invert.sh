#!/usr/bin/env bash
cs=$(grep -qi 'light' ~/dotfiles/color-scheme && echo "dark" || echo "light")
echo $cs | tee ~/dotfiles/color-scheme.tmp
mv ~/dotfiles/color-scheme.tmp ~/dotfiles/color-scheme
#emacsclient -e "(set-solarized-theme nil '$cs)" > /dev/null || true
if [ "$cs" = "dark" ]; then
    dconf write /org/gnome/desktop/interface/gtk-theme "'Adwaita-dark'"
    gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita-dark'
    gsettings set org.gnome.desktop.interface color-scheme prefer-dark
else
    dconf write /org/gnome/desktop/interface/gtk-theme "'Adwaita'"
    gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita'
    gsettings set org.gnome.desktop.interface color-scheme prefer-light
fi
