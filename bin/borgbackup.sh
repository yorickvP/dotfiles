#!/usr/bin/env bash
export BORG_REPO='zh3213@zh3213.rsync.net:jarvis'
export BORG_REMOTE_PATH=borg1
export BORG_PASSCOMMAND="pass sysadmin/jarvis-borg"
exec borg "$@"
