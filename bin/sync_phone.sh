#!/bin/sh

set -e

# "Notes" on getting my SD card to exfat
# fdisk as NTFS
# doas mkfs.exfat /dev/sd1i
# doas exfatlabel /dev/sd1i PHONE_SD
# doas mkfs.exfat
# doas mount.exfat /dev/sd1i ~/phone_sd

#
# Main
#

printf 'Syncing ~/cosmos subdirectories to ~/phone_local ...\n'
rsync -a --ignore-existing --del \
	"${HOME}"/cosmos/audiobooks \
	"${HOME}"/cosmos/books \
	"${HOME}"/cosmos/music \
	"${HOME}"/cosmos/pedagogy \
	"${HOME}"/phone_local

# Useful at least as a template to see what is there...
phone_local_extensions="$(find "${HOME}"/phone_local -type f |
	sed -rnE 's/^.+\.([a-zA-Z0-9]{3,4})$/\1/p' |
	sort |
	uniq |
	grep -E '(flac|m4a|mkv|mp3|mp4|wav)'
)"
# shellcheck disable=SC2034
readonly phone_local_extensions

# Track title should match filename pattern: <track_number> <track_title>
# Remove embeded images (would like to do that to "master" files as well...)
printf 'Modifying metadata in ~/phone_local ...\n'
find "${HOME}"/phone_local -type f \( \
	-iname '*.flac' -o \
	-iname '*.m4a' -o \
	-iname '*.mkv' -o \
	-iname '*.mp3' -o \
	-iname '*.mp4' -o \
	-iname '*.wav' \
\) | while read -r f
do
	filename="$(basename "${f}" | sed -rnE 's/^(.+)(\.[a-zA-Z0-9]{3,4})$/\1/p')"
	title="$(ffmpeg -nostdin -hide_banner -i "${f}" 2>&1 |
		grep -E '^[[:space:]]+title[[:space:]]+:' |
		awk -F ': ' '{ print $2; }'
	)"

	if test "${filename}" != "${title}"
	then
		ffmpeg -nostdin -hide_banner -i "${f}" \
			-metadata title="${filename}" \
			-codec copy \
			"${filename}.tmp"

		mv -v "${filename}.tmp" "${f}"
	fi
done

if df "${HOME}"/phone_sd >/dev/null 2>/dev/null && test -n "${*}"
then
	printf 'Syncing ~/phone_local to ~/phone_sd ...\n'
	rsync -rlpto --del "${HOME}"/phone_local/ "${HOME}"/phone_sd
fi
