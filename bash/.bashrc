
# don't put duplicate lines or lines starting with space in the history.
# See bash(1) for more options
HISTCONTROL=ignoreboth

# append to the history file, don't overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=100000
HISTFILESIZE=200000

alias nr="nix-repl '<nixpkgs>'"
alias ns="nix-shell"
alias nsp="nix-shell -p"
alias niA="nix-env -iA nixos."
alias subl="sublime3"
