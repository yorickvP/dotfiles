#!/usr/bin/env nix-shell
#!nix-shell -p bash -i bash grim libwebp

mkdir -p ~/periodic_screenshot
while true; do
    format="%Y-%m-%d_%H-%M_$(hostname).webp"

    if [[ $(pidof sway) -gt 0 ]]; then
        WAYLAND_DISPLAY=wayland-0 grim -c -t ppm /dev/stdout | cwebp -near_lossless 60 -progress -o ~/periodic_screenshot/$(date +$format) -- -
    fi
    sleep 2m
done

