#!/bin/sh
(
 yeganesh -x -- -fn "-*-termsyn-medium-*-*-*-12-*-*-*-*-*-*-*" -p "run: " -i -f -nb "#1D1E24" -nf "#8DA893" -sb "#1D1E24" -sf "#C18E44" $@
) | ${SHELL:-"/bin/sh"} &
