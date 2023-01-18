#!/usr/bin/env bash
MAC=88:C9:E8:AD:73:E8
bluetoothctl info "$MAC" | grep -q 'Connected: yes' &&
    bluetoothctl disconnect "$MAC"  || bluetoothctl connect "$MAC"
