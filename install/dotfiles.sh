#!/bin/sh

set -e

# ---
# Symlinks both cross-platform and platform-specific dotfiles
# ---

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

# Cross-platform
find dotfiles -type f | sed -E 's|^dotfiles/||g' | grep -Ev 'newsboat/.+_[^'"${ME_CONTEXT}"']' | sort | while read -r dotfile
do
	symlink_path="${HOME}/.${dotfile%_"${ME_CONTEXT}"}"

	test -d "$(dirname "${symlink_path}")" || mkdir -p "$(dirname "${symlink_path}")"

	if test "$(readlink "${symlink_path}")" != "${HOME}/dotfiles/dotfiles/${dotfile}"
	then
		if test -d "${symlink_path}"
		then
			cp -av "${symlink_path}" "${symlink_path}_$(date '+%Y%m%d-%H:%M:%S')" 
			rm -rf "${symlink_path}"
		elif test -e "${symlink_path}"
		then
			cp -av "${symlink_path}" "${symlink_path}_$(date '+%Y%m%d-%H:%M:%S')" 
			rm -f "${symlink_path}"
		fi

		ln -s "${HOME}/dotfiles/dotfiles/${dotfile}" "${symlink_path}"
	fi
done

# Platform-specific dotfiles
find dotfiles_"${ME_OPERATING_SYSTEM}" -type f | sed -E 's|^dotfiles_'"${ME_OPERATING_SYSTEM}"'/||g' | sort | while read -r dotfile
do
	symlink_path="${HOME}/.${dotfile%_"${ME_CONTEXT}"}"

	test -d "$(dirname "${symlink_path}")" || mkdir -p "$(dirname "${symlink_path}")"

	if test "$(readlink "${symlink_path}")" != "${HOME}/dotfiles/dotfiles_${ME_OPERATING_SYSTEM}/${dotfile}"
	then
		if test -d "${symlink_path}"
		then
			cp -av "${symlink_path}" "${symlink_path}_$(date '+%Y%m%d-%H:%M:%S')" 
			rm -rf "${symlink_path}"
		elif test -e "${symlink_path}"
		then
			cp -av "${symlink_path}" "${symlink_path}_$(date '+%Y%m%d-%H:%M:%S')" 
			rm -f "${symlink_path}"
		fi

		ln -s "${HOME}/dotfiles/dotfiles_${ME_OPERATING_SYSTEM}/${dotfile}" "${symlink_path}"
	fi
done

