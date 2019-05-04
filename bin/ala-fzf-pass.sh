set -euo pipefail

exec alacritty --class ala-fzf -e "$HOME/dotfiles/bin/fzf-pass-inner.sh"
