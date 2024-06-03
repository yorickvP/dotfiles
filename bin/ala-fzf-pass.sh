set -euo pipefail

alacritty msg create-window --class ala-fzf -e "$HOME/dotfiles/bin/fzf-pass-inner.sh" && exit 0
exec alacritty --class ala-fzf -e "$HOME/dotfiles/bin/fzf-pass-inner.sh"
