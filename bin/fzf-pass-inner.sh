set -euo pipefail

ENTRY=$(find ~/.password-store/ -name "*.gpg" -printf "%P\n" | sed -e 's/\.gpg$//' | fzf)
if [ -z "$ENTRY" ]; then
    exit 1
fi
PASSENTRY=$(pass "$ENTRY")
builtin echo "$PASSENTRY" | head -n1 | nohup wl-copy -f -n --sensitive &
WLCOPY_PID=$!
disown -h
nohup bash -c "sleep 30s; kill $WLCOPY_PID" &
disown -h

NOTIFICATION=$(builtin echo "$PASSENTRY" | sed 1d)
notify-send -t 6000 "$NOTIFICATION"
builtin echo "$NOTIFICATION"
