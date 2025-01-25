#!/usr/bin/env bash
gdbus call --session --dest com.mitchellh.ghostty --object-path /com/mitchellh/ghostty/window/1 --method org.gtk.Actions.Activate 'new_window' [] {} || exec ghostty
