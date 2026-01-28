#!/bin/sh

#
# Only enable audio/video recording when actually needed
#
# Inspired by: https://astro-gr.org/openbsd-zoom-et-al/
#

doas sysctl kern.audio.record=1
doas sysctl kern.video.record=1

ENABLE_WASM=1 ungoogled-chromium --incognito --user-data-dir="/tmp"
ENABLE_WASM=0

doas sysctl kern.audio.record=0
doas sysctl kern.video.record=0
