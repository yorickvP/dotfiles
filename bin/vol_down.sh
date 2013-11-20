#!/bin/bash

# lower volume by 1%
volume=$(amixer set Master playback 1%- | grep "t: Playback" | sed '{s/://}' | awk '{print $5}' | head -n 1 | cut -c2- | rev | cut -c3- | rev)
volnoti-show $volume
