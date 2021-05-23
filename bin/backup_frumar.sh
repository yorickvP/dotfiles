#!/bin/sh
export BORG_REPO="frumar.local:/data/yorick/backup"
export BORG_PASSCOMMAND="pass sysadmin/jarvis-borg"
borg create "::home-{hostname}-{user}-{now}" $HOME --exclude-from ~/dotfiles/misc/.borgignore -x  --compression=zstd -v
~/dotfiles/bin/borgbackup.sh prune --prefix "home-{hostname}-{user}" --keep-daily=4 --keep-weekly=4 --keep-monthly=6 --keep-yearly=2 --list --stats
