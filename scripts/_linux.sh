#!/bin/sh

set -e

#
# Immediate Exit Conditions
#

test "${0}" = "./scripts/setup.sh" || exit 1
test "${ME_OPERATING_SYSTEM}" = "Linux" || exit 1

#
# Main
#

