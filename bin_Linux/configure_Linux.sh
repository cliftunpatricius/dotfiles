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
# Directories
#

test -d ~/code || {
	mkdir -v ~/code
}

test -d ~/.ssh || {
	mkdir -v ~/.ssh
	chmod 700 ~/.ssh
}

#
# Packages
#

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

test -d ~/code/johnsonjh/OpenVi || {
	test -d ~/code/johnsonjh || {
		mkdir -v ~/code/johnsonjh
	}

	git clone https://github.com/johnsonjh/OpenVi.git ~/code/johnsonjh/OpenVi
}

(
	cd ~/code/johnsonjh/OpenVi
	git pull
	sudo dnf install -yq ncurses ncurses-devel
	export CFLAGS="-std=c99 -Wall"
	make
	sudo make install-strip
)

#
# GNOME
#

gsettings get org.gnome.desktop.input-sources xkb-options |
	grep -Eq 'caps:ctrl_modifier' || {
	gsettings set org.gnome.desktop.input-sources xkb-options \
		"['caps:ctrl_modifier']"
}

test "'prefer-dark'" = "$(gsettings get org.gnome.desktop.interface color-scheme)" || {
	printf 'Enabling dark mode ...\n'
	gsettings set org.gnome.desktop.interface color-scheme prefer-dark
}

test "true" = "$(gsettings get org.gnome.settings-daemon.plugins.color night-light-enabled)" || {
	printf 'Enabling Night Light ...\n'
	gsettings set org.gnome.settings-daemon.plugins.color night-light-enabled true
}

test "18.0" = "$(gsettings get org.gnome.settings-daemon.plugins.color night-light-schedule-from)" || {
	printf 'Sheduling Night Light begin ...\n'
	gsettings set org.gnome.settings-daemon.plugins.color night-light-schedule-from 18.00
}

test "6.0" = "$(gsettings get org.gnome.settings-daemon.plugins.color night-light-schedule-to)" || {
	printf 'Sheduling Night Light end ...\n'
	gsettings set org.gnome.settings-daemon.plugins.color night-light-schedule-to 06.00
}

#
# Shell
#

_shell="$(command -v oksh)"
readonly _shell
