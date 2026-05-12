#!/bin/sh

set -e

case "${SRANDRD_OUTPUT} ${SRANDRD_EVENT}" in
	"DP-4 connected")
		xrandr --output DP-4 --auto --left-of eDP-1
		;;
esac
