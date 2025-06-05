#!/bin/sh

set -e

#
# Immediate Exit Conditions
#

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
# Personal vs Work (borrowed from dotfiles/profile)
#

if printf '%s' "$(uname -n)" | grep -qE '^ws[[:digit:]]{4}$'
then
        ME_CONTEXT="work"
else
        ME_CONTEXT="personal"
fi

#
# Main
#

find dotfiles -type f | sed -E 's|^dotfiles/||g' | grep -Ev 'newsboat/.+_[^'"${ME_CONTEXT}"']' | sort | while read -r dotfile
do
	symlink_path="${HOME}/.${dotfile%_"${ME_CONTEXT}"}"

	test -d "$(dirname "${symlink_path}")" || echo "mkdir -p $(dirname "${symlink_path}")"

	if test "$(readlink "${symlink_path}")" != "${HOME}/dotfiles/dotfiles/${dotfile}"
	then
		if test -d "${symlink_path}"
		then
			echo cp -av "${symlink_path}" "${symlink_path}_$(date '+%Y%m%d-%H:%M:%S')" 
			echo rm -rf "${symlink_path}"
		elif test -e "${symlink_path}"
		then
			echo cp -av "${symlink_path}" "${symlink_path}_$(date '+%Y%m%d-%H:%M:%S')" 
			echo rm -f "${symlink_path}"
		fi

		echo ln -s "${HOME}/dotfiles/dotfiles/${dotfile}" "${symlink_path}"
	fi
done

#
# Use New Environment OR Warn
#

# Source the new ~/.profile in a backgroud process and sleep
#"${SHELL}" -c ". ${HOME}/.profile && sleep 10" &

# If the background process still exists, it is sleeping
# If it is sleeping, it did not exit during the sourcing of ~/.profile
# If it did not exit during the sourcing of ~/.profile, it is safe to use
#if test -n "$(jobs)"
#then
#	# Replace this shell with a new one and use the new ~/.profile
#	exec . "${HOME}"/.profile
#else
#	printf '\n!! Something went wrong while sourcing ~/.profile. Do _NOT_ exit this shell. !!\n' >&2
#fi

