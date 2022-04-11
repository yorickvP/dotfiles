#!/usr/bin/env bash
MAC=94:DB:56:79:7D:86
bluetoothctl info "$MAC" | grep -q 'Connected: yes' &&
    bluetoothctl disconnect "$MAC"  || bluetoothctl connect "$MAC"
