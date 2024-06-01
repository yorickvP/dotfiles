#!/usr/bin/env bash
cs=$(grep -qi 'light' ~/dotfiles/color-scheme && echo "dark" || echo "light")
echo $cs | tee ~/dotfiles/color-scheme.tmp
mv ~/dotfiles/color-scheme.tmp ~/dotfiles/color-scheme
ln -sf ~/dotfiles/alacritty/colors-$cs.toml ~/.config/alacritty/colors.toml
touch -h ~/.config/alacritty/alacritty.toml
#emacsclient -e "(set-solarized-theme nil '$cs)" > /dev/null || true
if [ "$cs" = "dark" ]; then
    dconf write /org/gnome/desktop/interface/gtk-theme "'Adwaita-dark'"
    gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita-dark'
else
    dconf write /org/gnome/desktop/interface/gtk-theme "'Adwaita'"
    gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita'
fi
