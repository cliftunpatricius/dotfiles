#!/bin/sh

set -e

# Symlinks both cross-platform and platform-specific dotfiles
./install/dotfiles.sh

# Symlinks executables and libraries for ~/bin and ~/lib, respectively
./install/bin_and_lib.sh

