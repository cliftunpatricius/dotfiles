#!/bin/sh

set -e

#
# Source Libraries
#

# shellcheck source=lib_Darwin/_unbound.sh
. "${HOME}"/lib/_unbound.sh

unbound_ensure_files

unbound_generate_dnssec_certs

unbound_place_new_conf_file_if_diff_and_reload

unbound_enable_service

unbound_enable_blacklist_updater

