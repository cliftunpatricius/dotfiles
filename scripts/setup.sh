#!/bin/sh

set -e

#
# Immediate Exit Conditions
#

# Do not run as `root`.
if test "$(id -u)" = "0"
then
	printf '%s\n' "Will not run as root." >&2
	exit 1
fi

if test "${PWD}" != "${HOME}/dotfiles"
then
	printf 'Must be executed from %s\n' "${HOME}/dotfiles" >&2
	exit 1
fi

#
# First-run Bootstrapping
#

link_created="false"
# shellcheck disable=SC2044
for link in $(find dotfiles -mindepth 1 -maxdepth 1)
do
	if test "${link}" = "ssh"
	then
		link="ssh/config"
	fi

	if test "$(readlink "${HOME}/.${link}")" != "${HOME}/dotfiles/dotfiles/${link}"
	then
		if test -d "${HOME}/.${link}"
		then
			rm -rf "${HOME}/.${link}"
		elif test -e "${HOME}/.${link}"
		then
			rm -f "${HOME}/.${link}"
		fi

		ln -s "${HOME}/dotfiles/dotfiles/${link}" "${HOME}/.${link}"
		link_created="true"
	fi
done

if test "${link_created}" = "true"
then
	printf '%s\n' "At least one missing symlink was created. Launch a new, interactive shell and run this script again." >&2
	exit
fi

# Ensure this is running in a new, interactive shell and picking up the custom environment variables.
if test -z "${ME_ARCHITECTURE}" \
	-o -z "${ME_OPERATING_SYSTEM}" \
	-o -z "${ME_HOSTNAME}" \
	-o -z "${ME_CONTEXT}" \
	-o -z "${EDITOR}" \
	-o -z "${VISUAL}" \
	-o -z "${ENV}"
then
	printf '%s\n' "At least one custom environment variable is missing. Exit the current shell and run this script again in a new, interactive shell to pickup the custom environment variables." >&2
	exit 1
fi

#
# Source Libraries
#

. scripts/_lib.sh
. dotfiles/_settings

#
# Script-specific Subroutines
#

usage() {
	echo "Usage
	${0} [-d|-f|-g|-h|-m|-r]

Parameters
	-d	Configures a DNS server on this machine

	-f	Configures a file server on this machine

	-g	Installs a GUI on this machine

	-h	Print this usage and exit

	-m	Configures a media server on this machine

	-r	Configures a router on this machine"
}

#
# Parse Parameters
#

# Defaults
ME_IS_DNS_SERVER="false"
ME_IS_FILE_SERVER="false"
ME_IS_MEDIA_SERVER="false"
ME_IS_ROUTER="false"
ME_HAS_GUI="false"

while getopts 'dfghmr' OPTION
do
	case "${OPTION}" in
		d)
			export ME_IS_DNS_SERVER="true"
			;;
		f)
			export ME_IS_FILE_SERVER="true"
			;;
		g)
			export ME_HAS_GUI="true"
			;;
		m)
			export ME_IS_MEDIA_SERVER="true"
			;;
		r)
			export ME_IS_ROUTER="true"
			;;
		?)
			usage >&2
			exit 1
			;;
	esac
done

#
# Cross-platform Configurations Requiring User Input
#

print_notice_message "Global git settings:"
prompt_user_for_git_setting "global" "user.email"
prompt_user_for_git_setting "global" "user.name"
prompt_user_for_git_setting "global" "push.default"
prompt_user_for_git_setting "global" "init.defaultBranch"
prompt_user_for_git_setting "global" "tag.gpgsign"
prompt_user_for_git_setting "global" "commit.gpgsign"
if test "$(git config --global commit.gpgsign)" = "true" -o "$(git config --global tag.gpgsign)" = "true"
then
	prompt_user_for_git_setting "global" "gpg.format"
	if test "$(git config --global gpg.format)" = "ssh"
	then
		prompt_user_for_git_setting "global" "gpg.ssh.allowedSignersFile"
	fi
	prompt_user_for_git_setting "global" "user.signingkey"
fi

print_notice_message "Git settings for ${HOME}/dotfiles:"
# Use a sub-shell for safer `cd`ing
(
	test "$(pwd)" = "${HOME}/dotfiles" || cd "${HOME}/dotfiles"

	prompt_user_for_git_setting "local" "user.email"
	prompt_user_for_git_setting "local" "user.name"
	prompt_user_for_git_setting "local" "push.default"
	prompt_user_for_git_setting "local" "init.defaultBranch"
	prompt_user_for_git_setting "local" "tag.gpgsign"
	prompt_user_for_git_setting "local" "commit.gpgsign"
	if test "$(git config --local commit.gpgsign)" = "true" -o "$(git config --local tag.gpgsign)" = "true"
	then
		prompt_user_for_git_setting "local" "gpg.format"
		if test "$(git config --local gpg.format)" = "ssh"
		then
			prompt_user_for_git_setting "local" "gpg.ssh.allowedSignersFile"
		fi
		prompt_user_for_git_setting "local" "user.signingkey"
	fi
)

# Newsboat
test -d "${HOME}/.newsboat" || mkdir "${HOME}/.newsboat"

readonly newsboat_files="config urls"
for f in ${newsboat_files}
do
	newsboat_path="${HOME}/.newsboat/${f}"
	old_symlink_dst="$(readlink "${HOME}/.newsboat/${f}" || printf '')"
	new_symlink_dst="${HOME}/.newsboat.d/${f}_${ME_CONTEXT}"

	if test -L "${newsboat_path}" -a "${old_symlink_dst}" = "${new_symlink_dst}"
	then
		break
	elif test -L "${newsboat_path}" -a "${old_symlink_dst}" != "${new_symlink_dst}"
	then
		rm -v "${newsboat_path}"
		ln -svw "${new_symlink_dst}" "${newsboat_path}"
	elif test -f "${newsboat_path}"
	then
		print_notice_message "File already exists: $(ls -l "${newsboat_path}")"
		default_response="n"
		prompt_user_with_default "${default_response}" 'Replace the aforementioned file (y/n)?'
		read -r actual_response
		actual_response="$(printf '%s' "${actual_response}" | sed '/^\s*$/d')"

		if test "${actual_response}" = "y"
		then
			rm -v "${newsboat_path}"
			ln -svw "${new_symlink_dst}" "${newsboat_path}"
		fi
	else
		ln -svw "${new_symlink_dst}" "${newsboat_path}"
	fi
done

#
# Platform-specific Configurations (may require user input)
#

# Read-only variables that are expected to be set by all of the platform-specific scripts:
_shell=""

if test "${ME_OPERATING_SYSTEM}" = "OpenBSD"
then
	. scripts/_openbsd.sh
elif test "${ME_OPERATING_SYSTEM}" = "FreeBSD"
then
	. scripts/_freebsd.sh
elif test "${ME_OPERATING_SYSTEM}" = "Linux"
then
	. scripts/_linux.sh
elif test "${ME_OPERATING_SYSTEM}" = "Darwin"
then
	. scripts/_darwin.sh
fi

#
# Cross-platform Configuration (does _not_ require user input)
#

# Create the parent directories of files that will not be committed to this public repo.
test -d "${HOME}/.ssh/config.d" || mkdir -p "${HOME}/.ssh/config.d"
chmod 750 "${HOME}/.ssh/config.d"

# Set shell.
if test "${SHELL}" != "${_shell}"
then
	if test "$("${_shell}" -c ': && printf OK')" = "OK"
	then
		chpass -s "${_shell}"
	else
		print_notice_message "Invalid shell path given (${_shell}); Shell remains ${SHELL}"
	fi
fi

# Clone and configure repositories.
test -d "${HOME}/code" || mkdir "${HOME}/code"

if test "${ME_CONTEXT}" = "work"
then
	test -d "${HOME}/code" || mkdir "${HOME}/code"
	test -f "${HOME}/code/.my_repos" || touch "${HOME}/code/.my_repos"

	while read -r url
	do
		repo_url="$(printf '%s' "${url}" | awk -F ';' '{print $1;}')"
		repo_org="$(printf '%s' "${repo_url}" | awk -F ':' '{print $2;}' | awk -F '/' '{print $1;}')"
		repo_name="$(printf '%s' "${repo_url}" | awk -F '/' '{print $2;}' | sed 's/\.git$//')"
		upstream_repo="$(printf '%s' "${url}" | awk -F ';' '{print $2;}')"

		test -d "${HOME}/code/${repo_org}" || mkdir "${HOME}/code/${repo_org}"

		if ! test -d "${HOME}/code/${repo_org}/${repo_name}"
		then
			git -C "${HOME}/code/${repo_org}" clone "${repo_url}"
		else
			printf '%s: %s\n' "$(print_green_text "${repo_org}/${repo_name}")" "Already cloned to ${HOME}/code/${repo_org}/${repo_name}"
		fi

		if test -z "$(git -C "${HOME}/code/${repo_org}/${repo_name}" remote -v | grep -E '^upstream[[:space:]]')"
		then
			git -C "${HOME}/code/${repo_org}/${repo_name}" remote add upstream "${upstream_repo}"
		else
			printf '%s: %s:\n%s\n' "$(print_green_text "${repo_org}/${repo_name}")" "Already has upstream set to" "$(git -C "${HOME}/code/${repo_org}/${repo_name}" remote -v | grep -E '^upstream[[:space:]]')"
		fi
	done < "${HOME}/code/.my_repos"
else
	test -d "${HOME}/code/me" || mkdir "${HOME}/code/me"
	test -f "${HOME}/code/me/.my_repos" || touch "${HOME}/code/me/.my_repos"
fi

# Misc. work configurations
if test "${ME_CONTEXT}" = "work"
then
	gh auth status > /dev/null 2> /dev/null || gh auth login

	az vm list > /dev/null 2> /dev/null || az login

	gcloud projects list > /dev/null || gcloud auth login
	test "$(gcloud config get disable_usage_reporting)" = "true" || gcloud config set disable_usage_reporting true
	gcloud components update

	# Use the Google account option
	test -z "$(infracost configure get api_key)" && infracost auth login
fi

