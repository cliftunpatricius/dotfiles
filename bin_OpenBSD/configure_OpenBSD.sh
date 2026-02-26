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
		printf 'Updating /etc/doas.conf ... '
		doas cp -a "${HOME}/dotfiles/config_OpenBSD/doas.conf" /tmp/doas.conf
		doas chmod 600 /tmp/doas.conf
		doas chown root:wheel /tmp/doas.conf
		doas cp -a /tmp/doas.conf /etc/doas.conf
		printf 'done\n'
	}
else
	printf 'Creating /etc/doas.conf ... '
	printf 'Enter the root user ' >&2
	su -l root -c "cp -a '${HOME}/dotfiles/config_OpenBSD/doas.conf' /tmp/doas.conf;
		chmod 600 /tmp/doas.conf;
		chown root:wheel /tmp/doas.conf;
		cp -a /tmp/doas.conf /etc/doas.conf"
	printf 'done\n'
fi

#
# X Server (via Xenodm)
#
# X server is run (even on "non-GUI" systems) for the following features:
# - Idle timeout suspend + screen lock
# - Lid closed suspend + screen lock
# - Session-wide ssh-add server
#

if doas rcctl ls off | grep -q '^xenodm$'
then
	printf 'Enabling xenodm ... '
	doas rcctl enable xenodm
	printf 'done\n'
	printf 'Log out and back in (or restart) to start xenodm.\n' >&2
fi

#
# Battery
#

# In combination with the contents of the ~/.x* files,
# this will cause the laptop to first lock and then to
# suspend when the lid is closed.
test -d /etc/apm || doas mkdir /etc/apm
test -f /etc/apm/suspend || {
	printf 'Touching /etc/apm/suspend ... '
	doas touch /etc/apm/suspend
	printf 'done\n'
}

cmp -s /etc/apm/suspend "${HOME}/dotfiles/config_OpenBSD/suspend" || {
	printf 'Updating /etc/apm/suspend ... '
	doas cp -a "${HOME}/dotfiles/config_OpenBSD/suspend" /etc/apm/suspend
	doas chown root:wheel /etc/apm/suspend
	doas chmod 750 /etc/apm/suspend
	printf 'done\n'
}

if doas rcctl ls off | grep -q '^apmd$'
then
	printf 'Enabling apmd in automatic mode ... '
	doas rcctl set apmd status on
	printf 'done\n'
fi

if test "$(rcctl get apmd flags)" != "-A -z 15"
then
	printf 'Configuring apmd to suspend when charge <= %s ... ' "15%"
	doas rcctl set apmd flags -A -z 15
	printf 'done\n'
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
	printf 'Configuring sndiod to "external" audio if available ... '
	doas rcctl set sndiod flags -f rsnd/0 -F rsnd/1
	printf 'done\n'
fi

#
# wsconsctl
#

cmp -s /etc/wsconsctl.conf "${HOME}/dotfiles/config_OpenBSD/wsconsctl.conf" || {
	printf 'Updating /etc/wsconsctl.conf ... '
	doas cp -a "${HOME}/dotfiles/config_OpenBSD/wsconsctl.conf" /etc/wsconsctl.conf
	doas chown root:wheel /etc/wsconsctl.conf
	doas chmod 644 /etc/wsconsctl.conf
	printf 'done\n'
}

#
# sysctl
#

cmp -s /etc/sysctl.conf "${HOME}/dotfiles/config_OpenBSD/sysctl.conf" || {
	printf 'Updating /etc/sysctl.conf ... '
	doas cp -a "${HOME}/dotfiles/config_OpenBSD/sysctl.conf" /etc/sysctl.conf
	doas chown root:wheel /etc/sysctl.conf
	doas chmod 644 /etc/sysctl.conf
	printf 'done\n'
}

#
# Packages
#

### Standard Packages

readonly packages="clamav
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
pdftk
plass
rsync--
shellcheck
spleen
tree
vorbis-tools
wireguard-tools
yt-dlp"

readonly gui_packages="firefox
mupdf--
openbsd-backgrounds
ungoogled-chromium
vimb"

readonly high_performance_packages="abcde
opam"

readonly high_performance_gui_packages="stellarium"

printf 'Installing/updating packages ...\n'
# shellcheck disable=SC2046
doas pkg_add $(printf '%s' "${packages}" | tr '\n' ' ')

if test "true" = "${ME_GUI}"
then
	printf 'Installing/updating GUI packages ...\n'
	# shellcheck disable=SC2046
	doas pkg_add $(printf '%s' "${gui_packages}" | tr '\n' ' ')
fi

if test "true" = "${ME_HIGH_PERFORMANCE}"
then
	printf 'Installing/updating high performance packages ...\n'
	# shellcheck disable=SC2046
	doas pkg_add $(printf '%s' "${high_performance_packages}" | tr '\n' ' ')
fi

if test "true" = "${ME_HIGH_PERFORMANCE}" -a "true" = "${ME_GUI}"
then
	printf 'Installing/updating high performance GUI packages ...\n'
	# shellcheck disable=SC2046
	doas pkg_add $(
		printf '%s' "${high_performance_gui_packages}" |
		tr '\n' ' '
	)
fi

### OCaml Source-based Packages

if command -v opam >/dev/null 2>/dev/null
then
	readonly opam_packages="cpdf"

	if test -z "$(command -v cpdf 2> /dev/null)"
	then
		printf 'Initializing opam ...\n'
		# Add an ~/.opamrc and possibly avoid init?
		opam init
	fi

	# Update present packages
	printf 'Updating opam package list ...\n'
	opam update -q --color=never
	printf 'Upgrading opam packages ...\n'
	opam upgrade -yq --color=never

	printf 'Installing any missing opam packages ...\n'
	# shellcheck disable=SC2046
	opam install -q --color=never \
		$(printf '%s' "${opam_packages}" | tr '\n' ' ')
fi

#
# ClamAV
#

# To-do: configure clamav to auto-update
