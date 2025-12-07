#!/usr/bin/env bash
# todo: not quite correct, but the gdbus call if ghostty's not running spawns the systemd service but misses a lot of env
pgrep ghostty-wrapp && gdbus call --session --dest com.mitchellh.ghostty --object-path /com/mitchellh/ghostty --method org.gtk.Application.Activate '{}' || exec ghostty
