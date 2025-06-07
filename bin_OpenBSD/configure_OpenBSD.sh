#!/bin/sh

set -e

#
# Immediate Exit Conditions
#

test "${0}" = "./scripts/setup.sh" || exit 1
test "${ME_OPERATING_SYSTEM}" = "OpenBSD" || exit 1

#
# Main
#

# Add `sndiod_flags=-f rsnd/0 -F rsnd/1` to /etc/rc.conf.local

test -d /etc/apm || mkdir /etc/apm
# touch /etc/apm/suspend && chmod +x
# apmd -A -z 15

