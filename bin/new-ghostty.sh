#!/usr/bin/env bash
gdbus call --session --dest com.mitchellh.ghostty --object-path /com/mitchellh/ghostty --method org.gtk.Application.Activate '{}' || exec ghostty
