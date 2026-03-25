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

test -d /etc/apm || doas mkdir /etc/apm

apm_files="$(find "${HOME}"/dotfiles/config_OpenBSD/apm -type f)"
readonly apm_files

for src in ${apm_files}
do
	dst="/etc/apm/$(basename "${src}")"

	test -f "${dst}" || {
		printf 'Touching %s ... ' "${dst}"
		doas touch "${dst}"
		printf 'done\n'
	}
	cmp -s "${dst}" "${src}" || {
		printf 'Updating %s ... ' "${dst}"
		doas cp -a "${src}" "${dst}"
		doas chown root:wheel "${dst}"
		doas chmod 750 "${dst}"
		printf 'done\n'
	}
done

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
# Printing (WIP)
#
# Inspiration:
# - https://openbsdhandbook.com/printing/#configuring-printing-with-lpd
# - https://www.paedubucher.ch/articles/basic-printing-on-openbsd/
#

# In case a USB connection is needed at some point
doas chown daemon /dev/ulpt0
doas chmod 600 /dev/ulpt0

cmp -s /etc/printcap "${HOME}/dotfiles/config_OpenBSD/printcap" || {
	printf 'Updating /etc/printcap ... '
	doas cp -a "${HOME}/dotfiles/config_OpenBSD/printcap" /etc/printcap
	doas chown root:wheel /etc/printcap
	doas chmod 644 /etc/printcap
	printf 'done\n'
}

if test ! -d /var/spool/output/brother
then
	doas mkdir -p /var/spool/output/brother
fi
doas chown -R daemon:daemon /var/spool/output/brother
doas chmod 770 /var/spool/output/brother

if doas rcctl ls off | grep -q '^lpd$'
then
	printf 'Enabling lpd ... '
	doas rcctl enable lpd
	printf 'done\n'
fi

#
# Packages
#

### Standard Packages

readonly packages="bible-kjv
castget
clamav
cmus
curl
enscript
exfat-fuse
flac
ffmpeg
flashrom
frotz
ghostscript--
git
got
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

readonly high_performance_gui_packages="celestia
stellarium"

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

#
# OCaml Source-based Packages
#

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
