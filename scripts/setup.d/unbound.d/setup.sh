#!/bin/sh

set -e

#
# Source Libraries
#

. "${HOME}"/.scripts/setup.d/unbound.d/_lib.sh

unbound_ensure_directories_and_or_symlinks

unbound_generate_dnssec_certs

unbound_place_new_conf_file_if_diff_and_reload

unbound_enable_service

