#!/bin/sh

#
# Variables
#

if test "${ME_OPERATING_SYSTEM}" = "OpenBSD"
then
	readonly _unbound_config_dir="/var/unbound/etc"
elif test "${ME_OPERATING_SYSTEM}" = "Darwin"
then
	readonly _unbound_config="/usr/local/etc/unbound/unbound.conf"
fi

readonly _unbound_conf="${_unbound_config_dir}/unbound.conf"
readonly _unbound_blacklist_conf="${_unbound_config_dir}/blacklist.conf"

#
# Subroutines
#

unbound_check_config_and_reload() {
diff -q /var/unbound/etc/unbound.conf "${HOME}"/.unbound.d/unbound.conf > /dev/null || diff_exit_code="${?}"

if test "${diff_exit_code}" -eq "1"
then
	if unbound-checkconf "${HOME}"/.unbound.d/unbound.conf
	then
		cp "${HOME}"/.unbound.d/unbound.conf /var/unbound/etc/unbound.conf

		# status Display server status. Exit code 3 if not running (the connection to the port is refused), 1 on error, 0 if running.
		sudo unbound-control status 2> /dev/null
		status_exit_code="${?}"
		
		if test "${status_exit_code}" -eq "3"
		then
			sudo unbound-control reload > /dev/null
		elif test "${status_exit_code}" -eq "1"
		then
			exit 1
		fi
		unset status_exit_code
	else
		exit 1
	fi
elif test "${diff_exit_code}" -gt "1"
then
	# Error message should have displayed to user with the diff command above; just exit.
	exit 1
fi
unset diff_exit_code
}

