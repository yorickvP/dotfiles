#!/bin/sh
set -euo pipefail
export PATH=$HOME/.nix-profile/bin:$PATH
mosquitto_sub -h frumar.home.yori.cc -u iot -P asdf -t "yorick/marvin/tracking" | jq --unbuffered -r 'if .task then if .started then "▶ \(.task.title)" else "⏸ \(.task.title)" end else "" end'
