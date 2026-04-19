#!/bin/sh
set -euo pipefail
export PATH=$HOME/.nix-profile/bin:$PATH
while IFS== read -r key value; do
  printf -v "$key" %s "$value" && export "$key"
done < /run/agenix/marvin-tracker
mosquitto_sub -h frumar.vpn.yori.cc -u "$MQTT_USER" -P "$MQTT_PASSWORD" -t "yorick/marvin/tracking" | jq --unbuffered -r 'if .task then if .started then "▶ \(.task.title)" else "⏸ \(.task.title)" end else "" end'
