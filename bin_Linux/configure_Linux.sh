#!/bin/sh

set -e

#
# Immediate Exit Conditions
#

test "${ME_OPERATING_SYSTEM}" = "Linux" || exit 1

#
# Main
#

# So far, some extra bootstrapping has been necessary to get to this point:
# - Disable preserving the working directory in new sessions in GNOME's terminal
# - After running ./install.sh, I had to manually `. ~/.profile` to get
#   environment variables to be available (a bash oddity?)
# - After setting user shell to oksh, still need to manually source for
#   environment variables AND while oksh is being used, $SHELL reports bash

gsettings get org.gnome.desktop.input-sources xkb-options |
	grep -Eq 'caps:ctrl_modifier' || {
	gsettings set org.gnome.desktop.input-sources xkb-options \
		"['caps:ctrl_modifier']"
}

sudo dnf install -y oksh
_shell="$(command -v oksh)"
readonly _shell
