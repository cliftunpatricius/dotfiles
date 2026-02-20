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

# Ensure critical custom environment variables exist
env | grep -Eq '^ME_(ARCHITECTURE|CONTEXT|OPERATING_SYSTEM)=' || {
	printf '%s\n' "At least one critical custom environment variable is missing. Run: ./install_dotfiles.sh" >&2
	exit 1
}

#
# Source Libraries
#

# shellcheck source=lib/_lib.sh
. "${HOME}"/lib/_lib.sh

#
# Script-specific Subroutines
#

usage() {
	echo "Usage
	${0} [-h]

Parameters
	-h	Print this usage and exit"
}

#
# Parse Parameters
#

# Defaults

while getopts 'h' OPTION
do
	case "${OPTION}" in
		h)
			usage
			exit
			;;
		?)
			usage >&2
			exit 1
			;;
	esac
done

#
# Cross-platform Configuration (does _not_ require user input)
#

# Create the parent directories of files that will not be committed to this public repo.
test -d "${HOME}/.ssh/config.d" || mkdir -p "${HOME}/.ssh/config.d"
chmod 750 "${HOME}/.ssh/config.d"


# Install Go packages
go_packages=""
if test "${ME_CONTEXT}" = "personal"
then
	# shellcheck disable=SC2269
	go_packages="${go_packages}"
elif test "${ME_CONTEXT}" = "work"
then
	# shellcheck disable=SC2269
	go_packages="${go_packages}
		github.com/erroneousboat/slack-term@latest"
fi
readonly go_packages

for p in ${go_packages}
do
	go install "${p}"
done

#
# Platform-specific Configurations (may require user input)
#

# Read-only variables that are expected to be set by all of the platform-specific scripts:
_shell=""

if test "${ME_OPERATING_SYSTEM}" = "OpenBSD"
then
	"${HOME}"/bin/configure_OpenBSD.sh
elif test "${ME_OPERATING_SYSTEM}" = "FreeBSD"
then
	# shellcheck source=bin_FreeBSD/configure_FreeBSD.sh
	. "${HOME}"/bin/configure_FreeBSD.sh
elif test "${ME_OPERATING_SYSTEM}" = "Linux"
then
	# shellcheck source=bin_Linux/configure_Linux.sh
	. "${HOME}"/bin/configure_Linux.sh
elif test "${ME_OPERATING_SYSTEM}" = "Darwin"
then
	# shellcheck source=bin_Darwin/configure_Darwin.sh
	. "${HOME}"/bin/configure_Darwin.sh
fi

# Set shell.
if test "${ME_OPERATING_SYSTEM}" != "OpenBSD"
then
	if test "${SHELL}" != "${_shell}"
	then
		if test "$("${_shell}" -c ': && printf OK')" = "OK"
		then
			chpass -s "${_shell}"
		else
			print_notice_message "Invalid shell path given (${_shell}); Shell remains ${SHELL}"
		fi
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

		test -d "${HOME}/code/${repo_org}" || mkdir "${HOME}/code/${repo_org}"

		if ! test -d "${HOME}/code/${repo_org}/${repo_name}"
		then
			printf '%s -> %s ... ' \
				"${repo_url}" \
				"${HOME}/code/${repo_org}/${repo_name}"
			git -C "${HOME}/code/${repo_org}" clone -q "${repo_url}"
			printf 'done\n'
		else
			printf '%s -> %s ok\n' \
				"${repo_url}" \
				"${HOME}/code/${repo_org}/${repo_name}"
		fi
	done < "${HOME}/code/.my_repos"
else
	test -d "${HOME}/code/me" || mkdir "${HOME}/code/me"
	test -f "${HOME}/code/me/.my_repos" || touch "${HOME}/code/me/.my_repos"
fi

# Misc. work configurations
if test "${ME_CONTEXT}" = "work"
then
	#gh auth status > /dev/null 2> /dev/null || gh auth login

	az vm list > /dev/null 2> /dev/null || az login

	gcloud projects list > /dev/null || gcloud auth login
	test "$(gcloud config get disable_usage_reporting)" = "true" || gcloud config set disable_usage_reporting true
	gcloud components update
	command -v gke-gcloud-auth-plugin >/dev/null 2>/dev/null || gcloud components install gke-gcloud-auth-plugin

	# Use the Google account option
	test -z "$(infracost configure get api_key)" && infracost auth login
fi

