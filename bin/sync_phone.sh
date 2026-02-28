#!/bin/sh

set -e

# "Notes" on getting my SD card to exfat
# fdisk as NTFS
# doas mkfs.exfat /dev/sd1i
# doas exfatlabel /dev/sd1i PHONE_SD
# doas mkfs.exfat
# doas mount.exfat /dev/sd1i ~/phone_sd

#
# Subroutines
#

usage()
{
	echo "usage"
}

#
# Parse Arguments
#

# Defaults
_directory=""
_force="false"
while getopts 'd:fh' OPTION
do
	case "${OPTION}" in
	d)
		readonly _directory="${OPTARG}"
		;;
	f)
		readonly _force="true"
		;;
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
# Main
#

#if test -n "${_directory}"
#then
#	"$(printf '%s' "${_directory}" | sed -E "s/^${HOME}\/cosmos\///")"
#else
	printf 'Syncing ~/cosmos subdirectories to ~/phone_local ...\n'
	rsync -a --ignore-existing --del \
		"${HOME}"/cosmos/audiobooks \
		"${HOME}"/cosmos/books \
		"${HOME}"/cosmos/music \
		"${HOME}"/cosmos/pedagogy \
		"${HOME}"/phone_local
#fi

# Modify "phone" files as necessary:
# - Track title should match filename pattern: <track_number> <track_title>
# - Remove embeded images (would like to do that to "master" files as well...)

printf 'Modifying FLAC metadata in phone_local ...\n'
find "${HOME}"/phone_local -type f -iname '*.flac' | while read -r f
do
	filename="$(basename "${f}")"
	title="$(metaflac --show-tag=title "${f}")"

	if test "${filename}" != "${title}"
	then
		metaflac --set-tag="title=${filename%.flac}" "${f}"
	fi
done

printf 'Modifying MP3 metadata in phone_local ...\n'
find "${HOME}"/phone_local -type f -iname '*.mp3' | while read -r f
do
	filename="$(basename "${f}")"
	title="$(mpg123-id3dump "${f}" 2>/dev/null |
		grep -EA 1 '^====[[:space:]]+ID3v2[[:space:]]+====$' |
		grep 'Title:' |
		awk -F 'Title: ' '{print $2;}'
	)"

	if test "${filename}" != "${title}"
	then
		id3tag --song="${filename%.mp3}" "${f}"
	fi
done

# Sync phone subdirectories to phone's SD card
if df "${HOME}"/phone_sd >/dev/null 2>/dev/null
then
	printf 'Syncing ~/phone_local to ~/phone_sd ...\n'
	rsync -rlpto --del "${HOME}"/phone_local/ "${HOME}"/phone_sd
fi
