#!/bin/sh

set -e

#
# Immediate Exit Conditions
#

# Do not run as `root`.
if test "$(id -u)" = "0"
then
	printf '%s\n' "Will not run as root." >&2
	exit 1
fi

#
# Source Libraries
#

# shellcheck source=lib/_lib.sh
. "${HOME}"/lib/_lib.sh

#
# Main
#

print_notice_message "Global git settings:"

prompt_user_for_git_setting "global" "user.email"
prompt_user_for_git_setting "global" "user.name"
prompt_user_for_git_setting "global" "push.default"
prompt_user_for_git_setting "global" "init.defaultBranch"
prompt_user_for_git_setting "global" "tag.gpgsign"
prompt_user_for_git_setting "global" "commit.gpgsign"

if test "$(git config --global commit.gpgsign)" = "true" -o "$(git config --global tag.gpgsign)" = "true"
then
	prompt_user_for_git_setting "global" "gpg.format"
	if test "$(git config --global gpg.format)" = "ssh"
	then
		prompt_user_for_git_setting "global" "gpg.ssh.allowedSignersFile"
	fi
	prompt_user_for_git_setting "global" "user.signingkey"
fi

if test "${ME_CONTEXT}" != "personal"
then
	# Use a sub-shell for safer `cd`ing
	(
		test "${PWD}" = "${HOME}/dotfiles" || cd "${HOME}/dotfiles"

		print_notice_message "Git settings for ${PWD}:"
		prompt_user_for_git_setting "local" "user.email"
		prompt_user_for_git_setting "local" "user.name"
		prompt_user_for_git_setting "local" "push.default"
		prompt_user_for_git_setting "local" "init.defaultBranch"
		prompt_user_for_git_setting "local" "tag.gpgsign"
		prompt_user_for_git_setting "local" "commit.gpgsign"
		if test "$(git config --local commit.gpgsign)" = "true" -o "$(git config --local tag.gpgsign)" = "true"
		then
			prompt_user_for_git_setting "local" "gpg.format"
			if test "$(git config --local gpg.format)" = "ssh"
			then
				prompt_user_for_git_setting "local" "gpg.ssh.allowedSignersFile"
			fi
			prompt_user_for_git_setting "local" "user.signingkey"
		fi
	)
fi

