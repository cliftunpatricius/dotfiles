#!/bin/sh

set -e

exit_upon_os_mismatch "${_required_os}"

# Add `sndiod_flags=-f rsnd/0 -F rsnd/1` to /etc/rc.conf.local

