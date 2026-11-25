#!/bin/sh

set -e

# Symlinks both cross-platform and platform-specific dotfiles
./install/dotfiles.sh

# Symlinks executables and libraries for "${HOME}"/bin and "${HOME}"/lib, respectively
./install/bin_and_lib.sh

