if [[ -n $SSH_CONNECTION ]]; then
export PS1='%m:%3~$(git_info_for_prompt)%# '
else
export PS1='%3~$(git_info_for_prompt)%# '
fi

export LSCOLORS="exfxcxdxbxegedabagacad"
export CLICOLOR=1
export GREP_COLOR='3;33'
export CDPATH=~/projects:~/

