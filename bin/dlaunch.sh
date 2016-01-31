#!/bin/sh
(
 yeganesh -x -- -fn "SourceCodePro:pixelsize=17" -p "run: " -i -f -nb "#002b36" -nf "#839496" -sb "#073642" -sf "#93a1a1" $@
) | ${SHELL:-"/bin/sh"} &
