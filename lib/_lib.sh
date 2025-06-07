#!/bin/sh

_me="${USER}"
readonly _me

_home="${HOME}"
readonly _home

#
# Colors
#

readonly foreground_green='\033[0;32m'
readonly foreground_yellow='\033[1;33m'
readonly foreground_red='\033[0;31m'
readonly foreground_reset='\033[0m'

print_green_text() { printf "${foreground_green}%s${foreground_reset}" "${*}"; }
print_yellow_text() { printf "${foreground_yellow}%s${foreground_reset}" "${*}"; }
print_red_text() { printf "${foreground_red}%s${foreground_reset}" "${*}"; }

#
# Messages
#

print_success_message() { printf '%s\n' "$(print_green_text "${*}")"; }
print_notice_message() { printf '%s\n' "$(print_yellow_text "${*}")" >&2; }
print_error_message() { printf '%s\n' "$(print_red_text "${*}")" >&2; }
print_error_message_from_file() { if test -s "${1}"; then print_error_message "$(cat "${1}")"; fi; }

#
# User Input
#

prompt_user_with_default() {
	unset prompt_user_with_default__prompt
	unset prompt_user_with_default__current

	if test "${#}" -lt "1"
	then
		print_error_message "usage: prompt_user_with_default <prompt> [current value]"
		return 1
	fi

	if test -n "${1}"
	then
		prompt_user_with_default__prompt="${1}"
	fi

	if test -n "${2}"
	then
		prompt_user_with_default__current="${2}"
		prompt_user_with_default__current="$(printf '%s' "${prompt_user_with_default__current}" | sed '/^\s*$/d')"
	fi

	if test -z "${prompt_user_with_default__current}"
	then
		printf '%s: ' "${prompt_user_with_default__prompt}"
	else
		printf '%s (%s): ' "${prompt_user_with_default__prompt}" "${prompt_user_with_default__current}"
	fi
}

prompt_user_for_git_setting() {
	unset prompt_user_for_git_setting__scope
	unset prompt_user_for_git_setting__setting
	unset prompt_user_for_git_setting__scoped_command
	unset prompt_user_for_git_setting__get_command
	unset prompt_user_for_git_setting__current_value
	unset prompt_user_for_git_setting__new_value

	if test "${#}" -ne "2"
	then
		print_error_message "usage: prompt_user_for_git_setting <global|local> <git setting string>"
		return 1
	fi

	if test -n "${1}"
	then
		prompt_user_for_git_setting__scope="${1}"
		prompt_user_for_git_setting__scope="$(printf '%s' "${prompt_user_for_git_setting__scope}" | sed '/^\s*$/d')"
	fi

	if test -n "${2}"
	then
		prompt_user_for_git_setting__setting="${2}"
	else
		print_error_message "usage: prompt_user_for_git_setting <global|local> <git setting string>"
		return 1
	fi

	if test "${prompt_user_for_git_setting__scope}" = "global"
	then
		prompt_user_for_git_setting__scoped_command="git config --global"
	elif test "${prompt_user_for_git_setting__scope}" = "local"
	then
		prompt_user_for_git_setting__scoped_command="git config --local"
	fi

	prompt_user_for_git_setting__get_command="${prompt_user_for_git_setting__scoped_command} ${prompt_user_for_git_setting__setting}"

	prompt_user_for_git_setting__current_value="$(${prompt_user_for_git_setting__get_command} || printf '')"

	prompt_user_with_default "Enter value for \`${prompt_user_for_git_setting__get_command}\`" "${prompt_user_for_git_setting__current_value}"
	read -r prompt_user_for_git_setting__new_value
	prompt_user_for_git_setting__new_value="$(printf '%s' "${prompt_user_for_git_setting__new_value}" | sed '/^\s*$/d')"

	if test -n "${prompt_user_for_git_setting__new_value}" -a "${prompt_user_for_git_setting__current_value}" != "${prompt_user_for_git_setting__new_value}"
	then
		if test -n "${prompt_user_for_git_setting__current_value}"
		then
			${prompt_user_for_git_setting__scoped_command} --unset "${prompt_user_for_git_setting__setting}"
		fi

		${prompt_user_for_git_setting__get_command} "${prompt_user_for_git_setting__new_value}"
	fi
}

