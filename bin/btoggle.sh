#!/usr/bin/env bash
MAC=80:99:E7:E4:01:78
bluetoothctl info "$MAC" | grep -q 'Connected: yes' &&
    bluetoothctl disconnect "$MAC"  || bluetoothctl connect "$MAC"
