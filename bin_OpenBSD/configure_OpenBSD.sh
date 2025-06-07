#!/bin/sh

set -e

#
# Immediate Exit Conditions
#

test "${ME_OPERATING_SYSTEM}" = "OpenBSD" || exit 1

#
# Battery
#

# In combination with the contents of the ~/.x* files,
# this will cause the laptop to first lock and then to
# suspend when the lid is closed.
test -d /etc/apm || doas mkdir /etc/apm
test -f /etc/apm/suspend || doas touch /etc/apm/suspend

cmp -s /etc/apm/suspend "${HOME}/dotfiles/config_OpenBSD/suspend" || {
	doas cp "${HOME}/dotfiles/config_OpenBSD/suspend" /etc/apm/suspend
	doas chmod +x /etc/apm/suspend
}

# Suspend if battery is at or below 15% charge
if test "$(rcctl get apmd flags)" != "-A -z 15"
then
	doas rcctl set apmd flags="-A -z 15"
fi

#
# Audio
#

# Need to look it up again, but I am pretty sure this means (on _my_ system)
# default to the built-in headphone jack, but use the expansion card headphone
# jack if it is plugged in (if not plugged in before boot, have to restart at
# least whatever program is outputing audio and possibly `sndiod` as well.
if test "$(rcctl get sndiod flags)" != "-f rsnd/0 -F rsnd/1"
then
	doas rcctl set sndiod flags="-f rsnd/0 -F rsnd/1"
fi

#
# wsconsctl
#

cmp -s /etc/wsconsctl.conf "${HOME}/dotfiles/config_OpenBSD/wsconsctl.conf" || {
	doas cp "${HOME}/dotfiles/config_OpenBSD/wsconsctl.conf" /etc/wsconsctl.conf
}

