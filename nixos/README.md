My nixos configurations.


Systems
=======

[frumar](https://en.wikipedia.org/wiki/Frumar)
--------

Physical [server](./roles/server.nix). Mostly used for files. (storage: 30 TB hdd + 256GB ssd, RAM: 16GB, 2 cores ht)

- prometheus
- grafana
- rabbitmq
- torrents
- plex

[pennyworth](https://en.wikipedia.org/wiki/Alfred_Pennyworth)
----------

[Server](./roles/server.nix).
Hetzner cloud VPS (Storage: 20GB, RAM: 2GB, 1 core)

- [website](./services/website.nix)
- [email](./services/mail.nix)
- irc/weechat
- vpn + http gateway for some services


[jarvis](https://en.wikipedia.org/wiki/Edwin_Jarvis)
--------

[workstation](./roles/workstation.nix).
dell xps 13 (RAM: 16GB, storage: 512GB ssd, 2 cores ht)


[blackadder](https://en.wikipedia.org/wiki/Edmund_Blackadder#Edmund_Blackadder_Esq._(Regency_Britain))
--------

[workstation](./roles/workstation.nix).
https://tweakers.net/productcollectie/wijzig/2583112/
ryzen 9 (RAM: 64GB, storage: 1TB ssd, 16 cores ht)

Maintenance
===========

Generating tor keys:

```
$(nix-build packages/shallot.nix --no-out-link)/bin/shallot -f tmp ^PATTERN
head -n3 tmp
tail -n +4 tmp > keys/ssh.HOSTNAME.key
shred tmp && rm tmp

```
