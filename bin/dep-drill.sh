#!/usr/bin/env nix-shell
#!nix-shell -I nixpkgs=flake:nixpkgs -p bkt fzf moreutils ncdu -i bash
set -euo pipefail

# todo's:
# - preserve(track) selection when hitting ctrl-s
#     https://github.com/junegunn/fzf/issues/3460
# - truncate nix store paths to fit terminal width
#     awk?
# - prevent hitting left-arrow on an empty stack

STATE=$(mktemp -d --suffix .nixfzf)
function cleanup {
    rm -rf "$STATE"
}
trap cleanup EXIT

if [ $# -ne 1 ]; then
  echo "Usage: dep-drill.sh /nix/store/..."
  exit 1
fi


# 3: sort -hk3 - sort by closure size, 2: sort -hk2 - own size
echo 3 > "$STATE"/sort
echo "$1" > "$STATE"/path
export SHELL=bash
export BKT_CACHE_DIR="$STATE/cache"
export BKT_TTL=10m
export FZF_DEFAULT_COMMAND='bkt -- nix path-info -rSsh $(tail -1 '"$STATE/path"') | sort -hk$(cat '"$STATE/sort"') | cut -c12-'

fzf --no-sort \
    --layout=reverse-list \
    --bind=load:last \
    --track \
    --preview 'bkt -- nix why-depends $(tail -1 '"$STATE/path"') /nix/store/{1} --precise --all' \
    --preview-window=down,30%,border-top \
    --preview-label=why-depends \
    --info=inline \
    --nth=1 \
    --bind 'ctrl-s:execute-silent(sed -i "s/2/4/g; s/3/2/g; s/4/3/g" '"$STATE/sort"')+track+reload-sync<'"$FZF_DEFAULT_COMMAND"'>+transform-border-label(sed -n "s/2/sorted by own size/p; s/3/sorted by closure size/p" '"$STATE/sort"')' \
    --bind 'ctrl-n:execute:ncdu /nix/store/{1}' \
    --bind 'right:execute-silent(echo /nix/store/{1} >> '"$STATE/path"')+reload-sync<'"$FZF_DEFAULT_COMMAND"'>+clear-query' \
    --bind 'left:execute-silent(uniq '"$STATE/path"' | head -n-1 | sponge '"$STATE/path"')+reload-sync<'"$FZF_DEFAULT_COMMAND"'>+clear-query' \
    --border-label="sorted by closure size" \
    --border=top \
    --header="ctrl-s: toggle sort, ctrl-n: ncdu"
