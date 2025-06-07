#!/bin/sh

set -e

# ---
# Symlinks executables and libraries for ~/bin and ~/lib, respectively
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

for dir in bin lib
do
	# Cross-platform
	find "${dir}" -mindepth 1 -type f | sed -E 's|^'"${dir}"'/||g' | sort | while read -r file
	do
		symlink_path="${HOME}/${dir}/${file%_"${ME_CONTEXT}"}"

		test -d "$(dirname "${symlink_path}")" || mkdir -p "$(dirname "${symlink_path}")"

		if test "$(readlink "${symlink_path}")" != "${HOME}/dotfiles/${dir}/${file}"
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

			ln -s "${HOME}/dotfiles/${dir}/${file}" "${symlink_path}"
		fi
	done

	# Platform-specific
	find "${dir}_${ME_OPERATING_SYSTEM}" -mindepth 1 -type f | sed -E 's|^'"${dir}_${ME_OPERATING_SYSTEM}"'/||g' | sort | while read -r file
	do
		symlink_path="${HOME}/${dir}/${file%_"${ME_CONTEXT}"}"

		test -d "$(dirname "${symlink_path}")" || mkdir -p "$(dirname "${symlink_path}")"

		if test "$(readlink "${symlink_path}")" != "${HOME}/dotfiles/${dir}_${ME_OPERATING_SYSTEM}/${file}"
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

			ln -s "${HOME}/dotfiles/${dir}_${ME_OPERATING_SYSTEM}/${file}" "${symlink_path}"
		fi
	done
done

