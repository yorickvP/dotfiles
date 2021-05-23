set -euo pipefail

ENTRY=$(find ~/.password-store/ -name "*.gpg" -printf "%P\n" | sed -e 's/\.gpg$//' | fzf)
if [ -z "$ENTRY" ]; then
    exit 1
fi
PASSENTRY=$(pass "$ENTRY")
# todo: kill after 30s
builtin echo "$PASSENTRY" | head -n1 | nohup wl-copy -f &
disown

NOTIFICATION=$(builtin echo "$PASSENTRY" | sed 1d)
notify-send -t 6000 "$NOTIFICATION"
builtin echo "$NOTIFICATION"
