#!/bin/sh

set -e

#
# Immediate Exit Conditions
#

test "${ME_OPERATING_SYSTEM}" = "Darwin" || exit 1

#
# Source Libraries
#

# shellcheck source=lib_Darwin/_Darwin.sh
. "${HOME}"/lib/_Darwin.sh

#
# Main
#

readonly _homebrew_tailscale="false"
readonly _unbound_user_and_group_id="499"

# fdesetup
if test "${ME_CONTEXT}" != "work" -a "$(fdesetup status)" = "FileVault is Off."
then
	prompt_user_with_default "Enable full-disk encryption? (only \"yes\" will enable it)" "no"
	read -r disk_encrypt_response

	test "${disk_encrypt_response}" = "yes" && sudo fdesetup enable -verbose
fi

_login_items="Terminal"
if test "${ME_CONTEXT}" = "work"
then
	_login_items="Keeper Password Manager,Mail,Google Drive,Slack,Firefox,${_login_items}"
	test "${_homebrew_tailscale}" = "false" && _login_items="Tailscale,${_login_items}"
fi
readonly _login_items

# Without this, the hostname displayed in terminal is often incorrect
# https://superuser.com/questions/357159/osx-terminal-showing-incorrect-hostname
# https://apple.stackexchange.com/questions/40734/why-is-my-host-name-wrong-at-the-terminal-prompt-when-connected-to-a-public-wifi
mac_hostname="$(scutil --get HostName 2> /dev/null)"
readonly mac_hostname
mac_computername="$(scutil --get ComputerName 2> /dev/null)"
readonly mac_computername
if test "${mac_hostname}" != "${mac_computername}"
then
	sudo scutil --set HostName "${mac_computername}"
fi

if ! test -f ~/Library/LaunchAgents/com.ldaws.CapslockEscape.plist
then
	# https://developer.apple.com/library/archive/technotes/tn2450/_index.html#//apple_ref/doc/uid/DTS40017618-CH1-KEY_TABLE_USAGES
	readonly caps_lock_code="0x700000039"
	# shellcheck disable=SC2034
	readonly escape_code="0x700000029"
	# shellcheck disable=SC2034
	readonly left_control_code="0x7000000E0"

	# Map Caps Lock to something else
readonly caps_lock_remapping='{"UserKeyMapping":[{"HIDKeyboardModifierMappingSrc":'"${caps_lock_code}"',"HIDKeyboardModifierMappingDst":'"${left_control_code}"'}]}'
hidutil property --set "${caps_lock_remapping}" > /dev/null

	# Now, make that persist
	if ! test -d "${HOME}/Library/LaunchAgents"
	then
		mkdir -p "${HOME}/Library/LaunchAgents"
	fi

	cat > "${HOME}/Library/LaunchAgents/com.ldaws.CapslockRemapping.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<!-- Place in ~/Library/LaunchAgents/ -->
<!-- launchctl load com.ldaws.CapslockRemapping.plist -->
<plist version="1.0">
  <dict>
    <key>Label</key>
    <string>com.ldaws.CapslockRemapping</string>
    <key>ProgramArguments</key>
    <array>
      <string>/usr/bin/hidutil</string>
      <string>property</string>
      <string>--set</string>
      <string>${caps_lock_remapping}</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
  </dict>
</plist>
EOF
	sudo launchctl enable system/com.ldaws.CapslockRemapping.plist
fi

# Install CLI packages.
brew_formulae="bash dash oksh tcsh zsh
	dark-mode
	defaultbrowser
	dehydrated
	dos2unix
	gh
	glow
	gopass
	gpg2
	jq
	libressl
	lynx
	mas
	newsboat
	nmap
	openssh
	openvi
	pdsh
	shellcheck
	smudge/smudge/nightlight
	tmux
	tree
	vegeta
	xclip
	yq"

# Current thinking about "reversing" specific use-case configurations (e.g., DNS server):
#  1. Check for an aspect that gets installed/configured
#  2. If detected, prompt user if the entire specific use-case should now be removed
#  3. Proceed accordingly
if test "${ME_CONTEXT}" = "personal" -a "${ME_IS_DNS_SERVER}" = "true"
then
	brew_formulae="${brew_formulae}
		unbound"
elif test "${ME_CONTEXT}" = "work"
then
	brew tap hashicorp/tap

	brew_formulae="${brew_formulae}
		act
		awscli
		azure-cli
		frotz
		go
		hadolint
		hashicorp/tap/terraform
		infracost
		kubelogin
		ruby@${RUBY_VERSION}
		tiger-vnc"
fi
readonly brew_formulae

# shellcheck disable=SC2086
brew install ${brew_formulae}

# Add Homebrew-installed shells to the list of allowed user shells for `chpass`
grep -q "${HOMEBREW_PREFIX}/bin/bash" /etc/shells || echo "${HOMEBREW_PREFIX}/bin/bash" | sudo tee -a /etc/shells
grep -q "${HOMEBREW_PREFIX}/bin/dash" /etc/shells || echo "${HOMEBREW_PREFIX}/bin/dash" | sudo tee -a /etc/shells
grep -q "${HOMEBREW_PREFIX}/bin/oksh" /etc/shells || echo "${HOMEBREW_PREFIX}/bin/oksh" | sudo tee -a /etc/shells
grep -q "${HOMEBREW_PREFIX}/bin/tcsh" /etc/shells || echo "${HOMEBREW_PREFIX}/bin/tcsh" | sudo tee -a /etc/shells
grep -q "${HOMEBREW_PREFIX}/bin/zsh" /etc/shells || echo "${HOMEBREW_PREFIX}/bin/zsh" | sudo tee -a /etc/shells

readonly _shell="${HOMEBREW_PREFIX}/bin/oksh"

# Install GUI packages.
brew_casks="firefox
	font-spleen
	utm"

if test "${ME_CONTEXT}" = "personal"
then
	brew_casks="${brew_casks}
		proton-pass"
elif test "${ME_CONTEXT}" = "work"
then
	brew_casks="${brew_casks}
		docker
		dotnet-sdk
		google-chrome
		google-cloud-sdk
		google-drive
		keeper-password-manager
		powershell
		slack
		windows-app
		zoom"
fi
readonly brew_casks

# shellcheck disable=SC2086
brew install --cask ${brew_casks}

if test "${ME_CONTEXT}" = "work" -a -n "${GEM_VERSION}"
then
	gem install --user-install \
		metadata-json-lint \
		puppet-lint \
		rubocop
fi

# If this is being used as a server of any kind, enable the SSH service
if test "${ME_CONTEXT}" = "personal" \
	&& test "${ME_IS_DNS_SERVER}" = "true" \
		-o "${ME_IS_FILE_SERVER}" = "true" \
		-o "${ME_IS_MEDIA_SERVER}" = "true" \
		-o "${ME_IS_ROUTER}" = "true"
then
	# Configure OpenSSH service
	sshd_config_cksum_before="$(cksum /usr/local/etc/ssh/sshd_config | awk '{print $1}')"
	sudo sed -i -E \
		-e 's/^#PermitRootLogin prohibit-password$/PermitRootLogin no/' \
		-e 's/^#PubkeyAuthentication yes$/PubkeyAuthentication yes/' \
		-e 's/^#PasswordAuthentication yes$/PasswordAuthentication no/' \
		-e 's/^#PermitEmptyPasswords no$/PermitEmptyPasswords no/' \
		/usr/local/etc/ssh/sshd_config 
	sshd_config_cksum_after="$(cksum /usr/local/etc/ssh/sshd_config | awk '{print $1}')"

	# Enable OpenSSH service
	sshd_plist_cksum_before="$(cksum /Library/LaunchDaemons/net.sshd.plist | awk '{print $1}')"
	echo '<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
	<dict>
		<key>Label</key>
		<string>net.sshd</string>

		<key>ProgramArguments</key>
		<array>
			<string>caffeinate</string>
			<string>-s</string>
			<string>/usr/local/sbin/sshd</string>
		</array>

		<key>KeepAlive</key>
		<true/>

		<key>RunAtLoad</key>
		<true/>
	</dict>
</plist>' | sudo tee /Library/LaunchDaemons/net.sshd.plist > /dev/null
	sshd_plist_cksum_after="$(cksum /Library/LaunchDaemons/net.sshd.plist | awk '{print $1}')"

	if test "${sshd_plist_cksum_after}" != "${sshd_plist_cksum_before}"
	then
		#sudo launchctl bootout system /Library/LaunchDaemons/net.sshd.plist #|| : # I do not yet understand why this fails sometimes
		#sudo launchctl disable system/net.sshd
		#sudo launchctl bootstrap system /Library/LaunchDaemons/net.sshd.plist #|| : # I do not yet understand why this fails sometimes
		sudo launchctl enable system/net.sshd
	fi

	if test "${sshd_config_cksum_after}" != "${sshd_config_cksum_before}" -o "${sshd_plist_cksum_after}" != "${sshd_plist_cksum_before}"
	then
		sudo launchctl kickstart -kp system/net.sshd
	else
		sudo launchctl kickstart -p system/net.sshd
	fi
fi

if test "${ME_CONTEXT}" = "work"
then
# As of right now, Tailscale is the _only_ app I have to use from the AppStore. My goal is to use _zero_ apps from the AppStore.
#
# I have two issues to still figure out:
#	1) Manually settings DNS seems to work for Firefox, but _not_ for Terminal.
#	   After a reboot, even Firefox is not happy until DNS is toggled back and forth, same as here: https://red.applefritter.com/r/Tailscale/comments/1g2tfi8/dns_problem_with_tailscaled_on_startup/
#	2) When last I tried, setting an exit node does not work and even, at least one time, "crashed" my networking.
if test "${_homebrew_tailscale}" = "true"
then
	readonly tailscale_dns="100.100.100.100"

	brew install tailscale

	if tailscale status 2>&1 | grep -q '^failed to connect'
	then
		sudo "${HOMEBREW_PREFIX}"/bin/tailscaled install-system-daemon
	fi

	if tailscale status 2>&1 | grep -q '^Logged out'
	then
		tailscale login
	fi

	if tailscale status 2>&1 | grep -q '^Tailscale is stopped'
	then
		tailscale up
	fi

	#sudo networksetup -listallnetworkservices
	if test "$(sudo networksetup -getdnsservers Wi-Fi)" != "${tailscale_dns}"
	then
		sudo networksetup -setdnsservers Wi-Fi "${tailscale_dns}"
	fi

	#tailscale set
else
	brew list | grep -q tailscale && brew remove tailscale
	command -v tailscaled > /dev/null 2> /dev/null && sudo tailscaled uninstall-system-daemon

	if ! test -f /Applications/Tailscale.app/Contents/MacOS/Tailscale
	then
		# Install the _oldest_ version of Tailscale from the AppStore that `mas` sees, because
		# it seems that the _latest_ one is some sort of pre-release package of sorts.
		tailscale_app_id="$(mas search Tailscale | grep -E '[[:digit:]]+[[:space:]]+Tailscale[[:space:]]+\(' | sort -V | tail -n 1 | awk '{print $1;}')"
		mas install "${tailscale_app_id}"
	else
		# Keep it up-to-date
		mas upgrade Tailscale
	fi
fi
fi

# Show hidden files in Finder
if test "$(defaults read -g AppleShowAllFiles)" != "1"
then
	defaults write -g AppleShowAllFiles -bool true
fi

# Set macOS to dark mode!
if test "$(dark-mode status)" != "on"
then
	dark-mode on
fi

# Set default browser!
defaultbrowser firefox > /dev/null

# Take care of those eyes
if test "$(nightlight schedule)" != "sunset to sunrise"
then
	# Do not exit upon a failure with this
	nightlight schedule start || :
fi

# Remove undesired Login Items
IFS=","
for current in $(osascript -e 'tell application "System Events" to get the name of every login item')
do
	current_normalized="$(printf '%s' "${current}" | sed -e 's/^[[:space:]]//' -e 's/[[:space:]]$//')"

	if ! printf '%s' "${_login_items}" | grep -q "${current_normalized}"
	then
		osascript -e 'tell application "System Events" to delete login item "'"${current_normalized}"'"'
	fi
done
unset IFS

# Add missing Login Items
IFS=","
for i in ${_login_items}
do
	if test "${i}" = "Terminal"
	then
		app_parent_dir="/System/Applications/Utilities"
	else
		app_parent_dir="/Applications"
	fi

	osascript -e 'tell application "System Events" to make login item at end with properties {name: "'"${i}"'",path:"'"${app_parent_dir}"'/'"${i}"'.app", hidden:false}'
done
unset IFS

#
# DNS Server Configuration (unbound)
#

if test "${ME_CONTEXT}" = "personal" -a "${ME_IS_DNS_SERVER}" = "true"
then
	create_darwin_system_user "_unbound" "${_unbound_user_and_group_id}" || if test "${?}" != "2"; then exit 1; fi

	# shellcheck source=bin_Darwin/configure_unbound.sh
	. "${HOME}"/bin/configure_unbound.sh
fi

printf 'The following configurations are not handled by this script:\n%s\n%s\n%s\n%s\n%s\n%s\n' \
'- lock screen immediately after display is off' \
'- 24-hour clock in both user and boot screens' \
'- trackpad tapping' \
'- trackpad speed' \
'- set keyboard to ABC - Extended' \
'- show bluetooth icon in menu bar'

