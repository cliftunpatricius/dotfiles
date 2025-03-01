#!/bin/sh

#
# Subroutines
#

create_darwin_system_user() {
	if test "${#}" -ne "2"
	then
		print_error_message "usage: create_new_system_user \"_<username>\" \"user ID\""
		return 1
	else
		create_new_system_user__username="${1}"
		create_new_system_user__id="${2}"
	fi

	if ! printf '%s' "${create_new_system_user__username}" | grep -q '^_'
	then
		print_error_message "create_new_system_user(): Prefix the system username with an underscore."
		return 1
	fi

	create_new_system_user__current_user_with_requested_id="$(dscl . -list /Users PrimaryGroupID | grep "${create_new_system_user__id}" || :)"
	create_new_system_user__current_group_with_requested_id="$(dscl . -list /Groups PrimaryGroupID | grep "${create_new_system_user__id}" || :)"

	if test -n "${create_new_system_user__current_user_with_requested_id}" -o -n "${create_new_system_user__current_group_with_requested_id}"
	then
		print_notice_message "The following user and/or group is already using ID ${create_new_system_user__id}:"
		print_notice_message "User: ${create_new_system_user__current_user_with_requested_id}"
		print_notice_message "Group: ${create_new_system_user__current_group_with_requested_id}"
		return 2
	fi

	sudo dscl . -create /Groups/"${create_new_system_user__username}"
	sudo dscl . -create /Groups/"${create_new_system_user__username}" PrimaryGroupID "${create_new_system_user__id}"
	sudo dscl . -create /Users/"${create_new_system_user__username}"
	sudo dscl . -create /Users/"${create_new_system_user__username}" RecordName "${create_new_system_user__username}" "$(printf '%s' "${create_new_system_user__username}" | sed 's/^_//')"
	sudo dscl . -create /Users/"${create_new_system_user__username}" RealName "Unbound DNS server"
	sudo dscl . -create /Users/"${create_new_system_user__username}" UniqueID "${create_new_system_user__id}"
	sudo dscl . -create /Users/"${create_new_system_user__username}" PrimaryGroupID "${create_new_system_user__id}"
	sudo dscl . -create /Users/"${create_new_system_user__username}" UserShell /usr/bin/false
	sudo dscl . -create /Users/"${create_new_system_user__username}" Password '*'
	sudo dscl . -create /Groups/"${create_new_system_user__username}" GroupMembership "${create_new_system_user__username}"
}

