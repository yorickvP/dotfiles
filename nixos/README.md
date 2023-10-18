This directory contains Nix code to deploy all of my machines. The main way to use this is via `ydeployer`.

Systems
=======

[blackadder](https://en.wikipedia.org/wiki/Edmund_Blackadder#Edmund_Blackadder_Esq._(Regency_Britain))
--------

Desktop [workstation](./roles/workstation.nix).
ryzen 9 3950x (RAM: 64GB, storage: 1TB ssd, 16 cores + hyperthreading)

There is a [list of components](https://tweakers.net/gallery/468325/inventaris/?inv_id=2583112) on tweakers.


- Main desktop with two 2560x1440 27" screens.
- It has a camera (sony alpha 6000) mounted on top of the left screen using a [smallrig super clamp](https://www.amazon.nl/-/en/gp/product/B08B63WXWN/).
- It has a Tobii Eye Tracker 4c attached to the left screen.


[frumar](https://en.wikipedia.org/wiki/Frumar)
--------

Physical NAS [server](./roles/homeserver.nix). Mostly used for files. (storage: 30 TB hdd + 256GB ssd, RAM: 64GB, 4 cpu cores). As of 2022-04-09, there is 12TB usable storage remaining.

There is a [list of components](https://tweakers.net/gallery/468325/inventaris/?inv_id=459811) on tweakers.

- prometheus
- grafana
- rabbitmq
- torrent client
- plex
- home-assistant
- unifi controller

[pennyworth](https://en.wikipedia.org/wiki/Alfred_Pennyworth)
----------

[Server](./roles/server.nix).
Hetzner [CX11](https://www.hetzner.com/cloud) cloud VPS (Storage: 20GB, RAM: 2GB, 1 core)

- [website](./services/website.nix)
- [email](./services/mail.nix)
- irc/weechat
- vpn + http gateway for some services


[jarvis](https://en.wikipedia.org/wiki/Edwin_Jarvis)
--------

[workstation](./roles/workstation.nix).
dell xps 13 (RAM: 16GB, storage: 512GB ssd, 2 cores + hyperthreading)

smithers
--------
[workstation](./roles/workstation.nix).

Main laptop.

thinkpad x1 carbon (gen 9) (RAM: 24GB, storage: 256GB ssd, 4 cores + hyperthreading)


