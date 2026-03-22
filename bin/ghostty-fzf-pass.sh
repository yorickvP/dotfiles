#!/bin/bash
set -euo pipefail

exec ghostty --gtk-single-instance=false --class=ala.fzf -e /bin/bash "$HOME/dotfiles/bin/fzf-pass-inner.sh"
