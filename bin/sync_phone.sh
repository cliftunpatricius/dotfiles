#!/bin/sh

set -e

#
# Main
#

# Sync some cosmos subdirectories to phone directory
openrsync -a --del \
	"${HOME}"/cosmos/audiobooks \
	"${HOME}"/cosmos/books \
	"${HOME}"/cosmos/music \
	"${HOME}"/cosmos/pedagogy \
	"${HOME}"/phone

# Modify "phone" files as necessary:
# - Track title should match filename pattern: <track_number> <track_title>
# - Remove embeded images (would like to do that to "master" files as well...)

# Sync phone subdirectories to phone's SD card
