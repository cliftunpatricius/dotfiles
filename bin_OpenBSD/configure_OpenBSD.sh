#!/bin/sh

set -e

#
# Immediate Exit Conditions
#

test "${ME_OPERATING_SYSTEM}" = "OpenBSD" || exit 1

#
# Main
#

# Need to look it up again, but I am pretty sure this means (on _my_ system)
# default to the built-in headphone jack, but use the expansion card headphone
# jack if it is plugged in (if not plugged in before boot, have to restart at
# least whatever program is outputing audio and possibly `sndiod` as well.
if test "$(rcctl get sndiod flags)" != "-f rsnd/0 -F rsnd/1"
then
	doas rcctl set sndiod flags="-f rsnd/0 -F rsnd/1"
fi

if test "$(rcctl get apmd flags)" != "-A -z 15"
then
	doas rcctl set apmd flags="-A -z 15"
fi

test -d /etc/apm || mkdir /etc/apm
# if diff, cp "${HOME}/dotfiles/config_OpenBSD/suspend" /etc/apm/suspend && chmod +x

