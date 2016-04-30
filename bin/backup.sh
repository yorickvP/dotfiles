#!/bin/sh
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

ionice -c3 duplicity /home/yorick \
  webdavs://yorickvp@yorickvp.stackstorage.com/remote.php/webdav//$(hostname | head -c3)_bak \
  --ssl-cacert-file /etc/ssl/certs/ca-bundle.crt \
  --encrypt-key yorick \
  --include-filelist ~/dotfiles/misc/dupignore \
  --asynchronous-upload \
  --volsize 100

# remove lockfile
rm -f /tmp/rbs.lock
