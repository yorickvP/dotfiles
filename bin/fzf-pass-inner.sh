set -euo pipefail

ENTRY=$(find ~/.password-store/ -name "*.gpg" -printf "%P\n" | sed -e 's/\.gpg$//' | fzf)
if [ -z "$ENTRY" ]; then
    exit 1
fi
PASSENTRY=$(pass "$ENTRY")
(builtin echo "$PASSENTRY" | head -n1 | timeout 30 wl-copy -f -n --sensitive) &
disown -h

NOTIFICATION=$(builtin echo "$PASSENTRY" | sed 1d)
if [ ! -z "${NOTIFICATION}" ]; then
  notify-send -t 6000 "$NOTIFICATION"
fi
builtin echo "$NOTIFICATION"
