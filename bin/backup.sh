#!/bin/sh
BACKUP_MACHINE="frumar.yori.cc"
DATE_FORMAT="+%Y-%m-%d"
BACKUP_DIR="/data/yorick/backup"

function is_locked() {
  # check for lockfile
  if [[ -f /tmp/rbs.lock ]]; then
    # process already running?
    if [[ "$(ps -p $(cat /tmp/rbs.lock) | wc -l)" -gt 1 ]]; then
echo "locked"
      return
fi
fi
echo "unlocked"
}

if [[ $(is_locked) == "locked" ]]; then
echo "process already running, aborting..."
  exit 1
fi

# create lockfile
rm -f /tmp/rbs.lock
echo $$ > /tmp/rbs.lock

echo "update local bup index..."
cd $HOME # do it here so that the bupignore paths work without rewriting
ionice -c3 bup index -u $HOME --xdev --exclude-from $HOME/dotfiles/misc/bupignore

# check if backup machine is available
#ping -w 5 -c 1 $BACKUP_MACHINE
#if [ $? -eq 0 ]; then
  # start backup

  echo "copy bup packs..."
  branch="$(hostname)-$(date $DATE_FORMAT)"
  ionice -c3 bup save -n $branch $HOME -r $BACKUP_MACHINE:$BACKUP_DIR/home/

  #echo "verify bup packs..."
  #cd $BACKUP_DIR/home
  #ionice -c3 bup -d . fsck -g -vv
#fi

# remove lockfile
rm -f /tmp/rbs.lock
