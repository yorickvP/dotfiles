
# don't put duplicate lines or lines starting with space in the history.
# See bash(1) for more options
HISTCONTROL=ignoreboth

# append to the history file, don't overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=100000
HISTFILESIZE=200000

alias nr="nix repl '<nixpkgs>'"
alias ns="nix-shell"
alias nsp="nix-shell -p"
alias niA="nix-env -iA nixos."
alias subl="sublime3"

# eval $(thefuck --alias)

            function fuck () {
                TF_PYTHONIOENCODING=$PYTHONIOENCODING;
                export TF_ALIAS=fuck;
                export TF_SHELL_ALIASES=$(alias);
                export TF_HISTORY=$(fc -ln -10);
                export PYTHONIOENCODING=utf-8;
                TF_CMD=$(
                    thefuck THEFUCK_ARGUMENT_PLACEHOLDER $@
                ) && eval $TF_CMD;
                unset TF_HISTORY;
                export PYTHONIOENCODING=$TF_PYTHONIOENCODING;
                history -s $TF_CMD;
            }
        
