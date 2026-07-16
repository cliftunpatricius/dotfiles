#!/bin/sh

# Do _not_ exit on error
set +e

readonly categories="channels
channels_video
oneoffs
oneoffs_video
playlists
playlists_video
playlists_order_by_date
playlists_order_by_date_video
playlists_order_by_title
playlists_order_by_title_video"

for i in ${categories}
do
	yt-dlp --config-locations ~/.yt-dlp/"${i}" -a ~/cosmos/documents/yt_dlp_todo_"${i}"
done
