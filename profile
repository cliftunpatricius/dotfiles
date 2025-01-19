#!/bin/sh

ME_ARCHITECTURE="$(uname -m)"
ME_OPERATING_SYSTEM="$(uname -s)"
ME_HOSTNAME="$(uname -n)"
export ME_ARCHITECTURE ME_OPERATING_SYSTEM ME_HOSTNAME

if printf '%s' "${ME_HOSTNAME}" | grep -qE '^ws[[:digit:]]{4}$'
then
        ME_CONTEXT="work"
else
        ME_CONTEXT="personal"
fi
export ME_CONTEXT

if test "$(uname -s)" = "Darwin"
then
	if test "$(uname -m)" = "arm64"
	then
		_homebrew_prefix="/opt/homebrew"
	elif test "$(uname -m)" = "x86_64"
	then
		_homebrew_prefix="/usr/local"
	fi
	readonly _homebrew_prefix

	eval "$("${_homebrew_prefix}"/bin/brew shellenv)"

	EDITOR="${HOMEBREW_PREFIX}/bin/ovi"
else
	EDITOR="$(command -v vi 2> /dev/null)"
fi
VISUAL="${EDITOR}"
export EDITOR VISUAL

# If there is no VISUAL or EDITOR from which to deduce the desired
# edit mode, assume vi(C)-style command line editing.
#if test -z "${VISUAL}" -a -z "${EDITOR}"
#then
#	set -o vi
#fi

if test -f "${HOME}"/.kshrc -a -r "${HOME}"/.kshrc
then
	ENV="${HOME}"/.kshrc
elif test -f "${HOME}"/.bashrc -a -r "${HOME}"/.bashrc
then
	ENV="${HOME}"/.bashrc
fi

export ENV

