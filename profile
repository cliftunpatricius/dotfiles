#!/bin/sh

ME_ARCHITECTURE="$(uname -m)"
ME_OPERATING_SYSTEM="$(uname -s)"
ME_HOSTNAME="$(uname -n)"
TERM="tmux-256color"
export ME_ARCHITECTURE ME_OPERATING_SYSTEM ME_HOSTNAME TERM

if printf '%s' "${ME_HOSTNAME}" | grep -qE '^ws[[:digit:]]{4}$'
then
        ME_CONTEXT="work"
else
        ME_CONTEXT="personal"
fi
export ME_CONTEXT

if test "${ME_CONTEXT}" = "work"
then
	# Puppet/OpenVox 8 needs ruby 3.2
	# Puppet/OpenVox 7 needs ruby 2.7
	PDK_PUPPET_VERSION="8"
	RUBY_VERSION="3.2"
	export PDK_PUPPET_VERSION RUBY_VERSION
fi

if test "$(uname -s)" = "Darwin"
then
	if test "$(uname -m)" = "arm64"
	then
		eval "$(/opt/homebrew/bin/brew shellenv)"
	elif test "$(uname -m)" = "x86_64"
	then
		eval "$(/usr/local/bin/brew shellenv)"
	fi

	if test -x "${HOMEBREW_PREFIX}/bin/ovi"
	then
		EDITOR="${HOMEBREW_PREFIX}/bin/ovi"
	else
		EDITOR="/usr/bin/vi"
	fi
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

GPG_TTY="$(tty)"
export GPG_TTY

if test -d "${HOMEBREW_PREFIX}/opt/ruby@${RUBY_VERSION}/bin"
then
	GEM_VERSION="$("${HOMEBREW_PREFIX}"/opt/ruby@"${RUBY_VERSION}"/bin/gem --version 2> /dev/null)"
	PATH="${HOMEBREW_PREFIX}/opt/ruby@${RUBY_VERSION}/bin:${PATH}"
	export GEM_VERSION PATH
fi

RUBY_GEMS_RUBY_VERSION="$(find "${HOMEBREW_PREFIX}"/lib/ruby/gems/ -maxdepth 1 -type d -name "${RUBY_VERSION}.*" | sort -rV | head -n 1 | xargs basename)"
if test -d "${HOME}/.gem/ruby/${RUBY_GEMS_RUBY_VERSION}/bin"
then
	PATH="${HOME}/.gem/ruby/${RUBY_GEMS_RUBY_VERSION}/bin:${PATH}"
	export PATH
fi

