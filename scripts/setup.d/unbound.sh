#!/bin/sh

set -e

#
# DNS Server Configuration (unbound)
#

if test "${ME_CONTEXT}" = "personal" -a "${_is_dns_server}" = "true"
then
	create_darwin_system_user "_unbound" "${_unbound_user_and_group_id}"

	{
		diff /var/unbound/etc/unbound.conf "${HOME}"/.unbound.d/unbound.conf > /dev/null 2> /dev/null
		exit_code="${?}"

		if test "${exit_code}" -eq "1"
		then
			cp "${HOME}"/.unbound.d/unbound.conf /var/unbound/etc/unbound.conf
		fi

		unset exit_code
	}

	if test "${ME_OPERATING_SYSTEM}" = "Darwin"
	then
		brew services start unbound
	fi
fi

