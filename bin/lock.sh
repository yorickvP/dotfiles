#!/bin/sh
xset dpms 0 0 10
( sleep 1s; xset dpms force off) &
( slock && xset dpms 0 0 600 )
