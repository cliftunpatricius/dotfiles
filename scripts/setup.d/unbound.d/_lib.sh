#!/bin/sh

#
# Variables
#

readonly _unbound_config_dir="/var/unbound/etc"
readonly _unbound_conf="${_unbound_config_dir}/unbound.conf"
readonly _unbound_blacklist_conf="${_unbound_config_dir}/blacklist.conf"

#
# Subroutines
#

unbound_ensure_macos_directories_and_symlinks() {
	if test "${ME_OPERATING_SYSTEM}" = "Darwin"
	then
		test -d /var/unbound_blacklist_cache || sudo mkdir -p /var/unbound_blacklist_cache
		test -d /var/unbound || sudo mkdir -p /var/unbound
		test -L /var/unbound/etc || sudo ln -s /usr/local/etc/unbound /var/unbound/etc
		test -L /var/unbound/db || sudo ln -s /usr/local/etc/unbound /var/unbound/db
	fi
}

unbound_enable_service() {
	if test "${ME_OPERATING_SYSTEM}" = "OpenBSD"
	then
		rcctl
	elif test "${ME_OPERATING_SYSTEM}" = "Darwin"
	then
		sudo chown -R _unbound:staff /usr/local/etc/unbound
		sudo chmod 660 /usr/local/etc/unbound/*

		echo '<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
	<dict>
		<key>Label</key>
		<string>net.unbound</string>
		<key>ProgramArguments</key>
		<array>
			<string>/usr/local/sbin/unbound</string>
			<string>-d</string>
			<string>-c</string>
			<string>/usr/local/etc/unbound/unbound.conf</string>
		</array>
		<key>KeepAlive</key>
		<true/>
		<key>RunAtLoad</key>
		<true/>
	</dict>
</plist>' | sudo tee /Library/LaunchDaemons/net.unbound.plist > /dev/null

		#sudo launchctl bootstrap system /Library/LaunchDaemons/net.unbound.plist
		sudo launchctl enable system/net.unbound
	fi
}

unbound_place_new_conf_file_if_diff_and_reload() {
	diff -q "${_unbound_conf}" "${HOME}"/.unbound.d/unbound.conf > /dev/null || diff_exit_code="${?}"
	test -z "${diff_exit_code}" && diff_exit_code="0"

	if test "${diff_exit_code}" -eq "1"
	then
		if unbound-checkconf "${HOME}"/.unbound.d/unbound.conf
		then
			cp "${HOME}"/.unbound.d/unbound.conf "${_unbound_conf}"

			# status Display server status. Exit code 3 if not running (the connection to the port is refused), 1 on error, 0 if running.
			sudo unbound-control status 2> /dev/null
			status_exit_code="${?}"

			if test "${status_exit_code}" -eq "3"
			then
				sudo unbound-control start
			elif test "${status_exit_code}" -eq "1"
			then
				exit 1
			else
				sudo unbound-control reload
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

