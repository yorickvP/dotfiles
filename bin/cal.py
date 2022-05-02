#!/usr/bin/env nix-shell
#!nix-shell -p python3 -p gcalcli -p python3.pkgs.i3ipc -i python3
#bin.y-cal-widget
from gcalcli.gcal import GoogleCalendarInterface
from datetime import datetime, timedelta
from collections import namedtuple
from gcalcli.cli import parse_cal_names
from dateutil.tz import tzlocal
import json
import subprocess
import sys
import i3ipc
from pathlib import Path

if not Path("~/.gcalcli_oauth").expanduser().exists():
    print(json.dumps({"text": "run gcalcli"}))
    sys.exit(0)

i3 = i3ipc.Connection()



gcal = GoogleCalendarInterface(
    cal_names=parse_cal_names(["yorickvanpelt@gmail.com", "yorick.vanpelt@tweag.io"]),
    config_folder=None, refresh_cache=False,
    use_cache=True,
    ignore_started=False,
    ignore_declined=True,
    color_date="yellow",
    override_color=False,
    military=True,
    #tsv=True,
)
start_date = datetime.now(tzlocal())

events = gcal._search_for_events(start=datetime.now(tzlocal()), end=start_date + timedelta(days=1), search_text=None)

opt = sys.argv[1]

def authuser(evt):
    if evt["gcalcli_cal"]["id"] == "yorickvanpelt@gmail.com":
        return 0
    else:
        return 1

def tooltip(evt):
    # todo: location
    return f"""
        <b>{evt["summary"]}</b>
        {evt["s"].strftime("%b %d %H:%M")} - {evt["e"].strftime("%H:%M")}
    """

def click(evt):
    # todo: only on certain time before
    if 'hangoutLink' in evt:
        # jump into video call
        url = evt["hangoutLink"] + "?authuser=" + str(authuser(evt))
        subprocess.call(["playerctl", "pause"])
        i3.command("focus output 'DVI-D-1', workspace --no-auto-back-and-forth 9")
        subprocess.call(["chromium", url])
    else:
        subprocess.call(["xdg-open", evt["htmlLink"]])

def rightclick(evt):
    subprocess.call(["xdg-open", "https://calendar.google.com"])

events = [e for e in events if not gcal._DeclinedEvent(e)]
if opt == "dump":
    print(json.dumps(events, default=str))

if opt == "click":
    click(events[0])

if opt == "rightclick":
    rightclick(events[0])

if opt == "tooltip":
    print(tooltip(events[0]))
        
if opt == "list": # todo: rename to first
    for evt in events:
        icon = ""
        # todo: tooltip
        if 'hangoutLink' in evt:
            icon = ""
        print(json.dumps({
            "text": evt["s"].strftime("%H:%M") + " " + evt["summary"] + " " + icon,
            "class": f"user-{authuser(evt)}",
            "tooltip": tooltip(evt)
        }))
        break