#!/bin/sh

set -e

#
# Linux is primarily for when a BSD is not an option. Support will be minimal.
#
# Oddities/pending issues:
# - Had to disable preserving the working directory in new sessions of GNOME's terminal
# - Launching tmux gets following error: oksh: /etc/profile.d/lang.sh[62]: syntax error: `< ' unexpected
#

#
# Immediate Exit Conditions
#

test "${ME_OPERATING_SYSTEM}" = "Linux" || exit 1

#
# Libraries
#

# shellcheck source=lib/_gnome.sh
. "${HOME}"/lib/_gnome.sh

#
# Directories
#

test -d "${HOME}"/code || {
	mkdir -v "${HOME}"/code
}

test -d "${HOME}"/.ssh || {
	mkdir -v "${HOME}"/.ssh
	chmod 700 "${HOME}"/.ssh
}

#
# Packages
#

### Remove Packages

# Remove any default packages?

### Standard Packages

readonly packages="clamav
	clang
	curl
	git
	make
	oksh
	shellcheck
	tree
	firefox
	chromium"

printf 'Installing packages ...\n'
# shellcheck disable=SC2086
sudo dnf install -yq ${packages}

### Proton Packages

command -v proton-pass >/dev/null || {
	printf 'Installing Proton Pass ...\n'
	curl -Ls -o /tmp/ProtonPass.rpm https://proton.me/download/pass/linux/ProtonPass.rpm
	sudo rpm -i --force --nosignature /tmp/ProtonPass.rpm
}

command -v protonvpn-app >/dev/null || {
	printf 'Installing Proton VPN ...\n'
	curl -Ls -o /tmp/protonvpn-stable-release-1.0.5-1.noarch.rpm \
		"https://repo.protonvpn.com/fedora-$(cat /etc/fedora-release | cut -d ' ' -f 3)-stable/protonvpn-stable-release/protonvpn-stable-release-1.0.5-1.noarch.rpm"
	sudo dnf install -yq /tmp/protonvpn-stable-release-1.0.5-1.noarch.rpm
	sudo dnf check-update --refresh
	sudo dnf install -yq proton-vpn-gnome-desktop

	# To disable kill switch after unintalling
	#nmcli connection show --active
	#nmcli connection delete [connection name]
}

command -v proton-drive >/dev/null || {
	printf 'Installing Proton Drive CLI ...\n'
	curl -Ls https://proton.me/download/drive/cli/0.9.0/linux-x64/proton-drive |
		sudo tee /usr/local/bin/proton-drive >/dev/null
}
sudo chown root:bin /usr/local/bin/proton-drive
sudo chmod 755 /usr/local/bin/proton-drive

proton-drive album list >/dev/null 2>/dev/null || {
	printf 'Logging-in to Proton Drive ...\n'
	proton-drive auth login
}

command -v proton-mail >/dev/null || {
	printf 'Installing Proton Mail ...\n'
	curl -Ls -o /tmp/ProtonMail-desktop-beta.rpm https://proton.me/download/mail/linux/ProtonMail-desktop-beta.rpm
	sudo rpm --import https://proton.me/download/mail/linux/RPM-GPG-KEY-proton-mail
	rpm --checksig /tmp/ProtonMail-desktop-beta.rpm
	sudo dnf install -yq /tmp/ProtonMail-desktop-beta.rpm
}

#
# Packages From Source
#

test -d "${HOME}"/code/johnsonjh/OpenVi || {
	test -d "${HOME}"/code/johnsonjh || {
		mkdir -v "${HOME}"/code/johnsonjh
	}

	git clone https://github.com/johnsonjh/OpenVi.git "${HOME}"/code/johnsonjh/OpenVi
}

(
	cd "${HOME}"/code/johnsonjh/OpenVi
	git pull
	sudo dnf install -yq ncurses ncurses-devel
	export CFLAGS="-std=c99 -Wall"
	make
	sudo make install-strip
)

#
# GNOME
#

gnome_swap_caps_and_lctl
gnome_set_dark_mode
gnome_enable_night_light
gnome_schedule_night_light_from 18.0
gnome_schedule_night_light_to 6.0

#
# Shell
#

_shell="$(command -v oksh)"
readonly _shell
