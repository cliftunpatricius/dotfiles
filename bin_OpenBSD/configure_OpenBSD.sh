#!/bin/sh

set -e

#
# Immediate Exit Conditions
#

test "${ME_OPERATING_SYSTEM}" = "OpenBSD" || exit 1

#
# Configure doas(1) via doas.conf(5)
#

if test -f /etc/doas.conf
then
	doas cmp -s /etc/doas.conf "${HOME}/dotfiles/config_OpenBSD/doas.conf" || {
		doas cp -a "${HOME}/dotfiles/config_OpenBSD/doas.conf" /tmp/doas.conf
		doas chmod 600 /tmp/doas.conf
		doas chown root:wheel /tmp/doas.conf
		doas cp -a /tmp/doas.conf /etc/doas.conf
	}
else
	printf 'Enter the root user ' >&2
	su -l root -c "cp -a '${HOME}/dotfiles/config_OpenBSD/doas.conf' /tmp/doas.conf;
		chmod 600 /tmp/doas.conf;
		chown root:wheel /tmp/doas.conf;
		cp -a /tmp/doas.conf /etc/doas.conf"
fi

#
# GUI or No
#

if doas rcctl ls on | grep -q '^xenodm$'
then
	ME_GUI="true"
else
	ME_GUI="false"
fi
export ME_GUI

#
# Battery
#

# In combination with the contents of the ~/.x* files,
# this will cause the laptop to first lock and then to
# suspend when the lid is closed.
test -d /etc/apm || doas mkdir /etc/apm
test -f /etc/apm/suspend || doas touch /etc/apm/suspend

cmp -s /etc/apm/suspend "${HOME}/dotfiles/config_OpenBSD/suspend" || {
	doas cp -a "${HOME}/dotfiles/config_OpenBSD/suspend" /etc/apm/suspend
	doas chown root:wheel /etc/apm/suspend
	doas chmod 750 /etc/apm/suspend
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
	doas cp -a "${HOME}/dotfiles/config_OpenBSD/wsconsctl.conf" /etc/wsconsctl.conf
	doas chown root:wheel /etc/wsconsctl.conf
	doas chmod 644 /etc/wsconsctl.conf
}

#
# sysctl
#

cmp -s /etc/sysctl.conf "${HOME}/dotfiles/config_OpenBSD/sysctl.conf" || {
	doas cp -a "${HOME}/dotfiles/config_OpenBSD/sysctl.conf" /etc/sysctl.conf
	doas chown root:wheel /etc/sysctl.conf
	doas chmod 644 /etc/sysctl.conf
}

#
# Packages
#

### Standard Packages

readonly packages="abcde
clamav
cmus
curl
flac
ffmpeg
flashrom
frotz
git
lynx
mplayer
newsboat
opam
pdftk
shellcheck
spleen
tree
vorbis-tools
wireguard-tools
yt-dlp"

readonly gui_packages="firefox
mupdf--
openbsd-backgrounds
stellarium
ungoogled-chromium"

# shellcheck disable=SC2046
doas pkg_add $(printf '%s' "${packages}" | tr '\n' ' ')

if test "true" = "${ME_GUI}"
then
	# shellcheck disable=SC2046
	doas pkg_add $(printf '%s' "${gui_packages}" | tr '\n' ' ')
fi

### OCaml Source-based Packages

readonly opam_packages="cpdf"

if test -z "$(command -v cpdf 2> /dev/null)"
then
	# Add an ~/.opamrc and possibly avoid init?
	opam init
fi

# Update present packages
opam update
opam upgrade -y

# Install whatever may be new this round
# shellcheck disable=SC2046
opam install $(printf '%s' "${opam_packages}" | tr '\n' ' ')

#
# ClamAV
#

# To-do: configure clamav to auto-update
