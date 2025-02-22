#!/bin/sh
# shellcheck disable=SC2034,SC2317

set -e

#
# Blacklist undesired domains
#
# Modified from https://www.tumfatig.net/2022/ads-blocking-with-openbsd-unbound8/
#

#
# Global Constants
#

# The whitelist of domains to remove, if found, from blacklists
readonly whitelist="faithlife.com
auth.faithlife.com
goodreads.com
logos.com
proton.me
protonvpn.com
reddit.com
humblebundle.com
razer.com
nvidia.com
discord.gg
discord.com
discordapp.com
myheritage.com
apps.apple.com"

#whitelist_sed_deletions=""
grep_ignores=""
for domain in ${whitelist}
do
	domain_formatted="$(printf '%s' "${domain}" | sed -e 's/\./\\./g')"
	#whitelist_sed_deletions="${whitelist_sed_deletions} -e '/\\\"${domain_escaped}\\\"/d'"
	
	if test -z "${grep_ignores}"
	then
		grep_ignores="${domain_formatted}"
	else
		grep_ignores="${grep_ignores}|${domain_formatted}"
	fi
done
#readonly whitelist_sed_deletions
readonly grep_ignores

# The master list of providers that is used to build the final blacklist
readonly providers="adguard
adaway
pi_hole
stopforumspam
malicious
pl_ad_tracking
adguard_french
ut1"

# UT1 categories: to use, include "ut1" in the master list above
# https://dsi.ut-capitole.fr/blacklists/index_en.php
readonly ut1_categories="adult
arjel
astrology
cryptojacking
dating
educational_games
gambling
games
lingerie
manga
marketingware
mixed_adult
phishing
publicite
redirector
remote-control
sexual_education
social_networks
stalkerware
warez"

temp_normalized_conf="$(mktemp)"
readonly temp_normalized_conf

temp_final_conf="$(mktemp)"
readonly temp_final_conf

temp_download_dir="${1:-$(mktemp -d)}"
readonly temp_download_dir

readonly blacklist_conf="/var/unbound/etc/blacklist.conf"
readonly cache_dir="/var/unbound_blacklist_cache"

# AdGuard DNS filter
readonly adguard_url="https://adguardteam.github.io/AdGuardSDNSFilter/Filters/filter.txt"
readonly adguard_cache="${cache_dir}/adguard"

# AdAway default blocklist
readonly adaway_url="https://adaway.org/hosts.txt"
readonly adaway_cache="${cache_dir}/adaway"

# From Pi-hole
readonly pi_hole_url="https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts"
readonly pi_hole_cache="${cache_dir}/pi_hole"

# StopForumSpam
readonly stopforumspam_url="https://www.stopforumspam.com/downloads/toxic_domains_whole.txt"
readonly stopforumspam_cache="${cache_dir}/stopforumspam"

# Malicious Domains Unbound Blocklist
readonly malicious_url="https://malware-filter.gitlab.io/malware-filter/urlhaus-filter-unbound.conf"
readonly malicious_cache="${cache_dir}/malicious"

# Peter Lowe's Ad and tracking server list
readonly pl_ad_tracking_url="https://pgl.yoyo.org/adservers/serverlist.php?showintro=0;hostformat=hosts"
readonly pl_ad_tracking_cache="${cache_dir}/pl_ad_tracking"

# AdGuard Français
readonly adguard_french_url="https://raw.githubusercontent.com/AdguardTeam/AdguardFilters/master/FrenchFilter/sections/adservers.txt"
readonly adguard_french_cache="${cache_dir}/adguard_french"

# The Université Toulouse 1 Blacklist
#readonly ut1_url="ftp://ftp.ut-capitole.fr/pub/reseau/cache/squidguard_contrib"
readonly ut1_url="https://dsi.ut-capitole.fr/blacklists/download"

#
# Subroutines
#

is_temp_blacklist_conf_valid() {
	# Ensure not empty
	if ! test -s "${temp_final_conf}"
	then
		return 1
	fi

	# If the file conatins only minimal error information,
	# it is likely a bad file, so reject it
	# Check for file size here... less than 500 bytes reject?
	# Would be better to "ensure" that _nothing_ is written
	# to the file in the event of an error
	if test "$(stat -f %Uz "${temp_final_conf}")" -lt "500"
	then
		return 1
	fi
}

normalize_adguard() {
	cat | sed -nre 's/^\|\|([a-zA-Z0-9\_\-\.]+)\^$/local-zone: "\1" always_nxdomain/p'
}

normalize_adaway() {
	cat | awk '/^127.0.0.1 / { print "local-zone: \"" $2 "\" always_nxdomain" }'
}

normalize_pi_hole() {
	cat | awk '/^0.0.0.0 / { print "local-zone: \"" $2 "\" always_nxdomain" }'
}

normalize_stopforumspam() {
	cat | awk '{ print "local-zone: \"" $1 "\" always_nxdomain" }'
}

normalize_malicious() {
	cat | grep '^local-zone: '
}

normalize_pl_ad_tracking() {
	cat | awk '/^127.0.0.1 / { print "local-zone: \"" $2 "\" always_nxdomain" }'
}

normalize_adguard_french() {
	cat | sed -nre 's/^\|\|([a-zA-Z0-9\_\-\.]+)\^.*$/local-zone: "\1" always_nxdomain/p'
}

normalize_ut1() {
	cat | awk '{ print "local-zone: \"" $1 "\" always_nxdomain" }'
}

download_hosts() {
	_hosts="${1}"
	_url="${2}"

	test -z "${_hosts}" -o -z "${_url}" && return 1

	#_ftp_output="$(ftp -MV -w 5 -T -o "${_hosts}" "${_url}" 2>&1; printf '|%s' "${?}")"

	curl -z "${_hosts}" -o "${_hosts}" "${_url}" > /dev/null 2> /dev/null || return 1

	#if printf '%s' "${_ftp_output}" | grep -q 'File is not modified on the server'
	#then
	#	printf 'No updates for %s\n' "${_hosts}" >&2
	#	logger "${0}: no updates for ${_hosts}."
	#	return 2
	#elif test "$(printf '%s' "${_ftp_output}" | awk -F '|' '{ print $NF }')" -ne "0"
	#then
	#	printf 'Failed to download %s\n' "${_url}" >&2
	#	logger "${0}: failed to download ${_url}."
	#	return 1
	#fi
}

initialize_download_file() {
	_path="${1}"
	shift

	test -z "${_path}" && return 1

	if ! test -f "${_path}"
	then
		# Set the modification time to the distant past to ensure
		# the modification time on the file-to-download is newer
		# than the cache (assuming the file-to-download has an
		# accurate timestamp)
		if ! touch -m -d 1273-01-01T00:00:00 "${_path}"
		then
			printf 'Failed to initialize %s\n' "${_path}" >&2
			logger "${0}: failed to initialize ${_path}."
			return 1
		fi
	fi
}

#trap 'rm -f "${temp_normalized_conf}" && echo Removed ${temp_normalized_conf} >&2; rm -f "${temp_final_conf}" && echo Removed ${temp_final_conf} >&2; rm -fr "${temp_download_dir}" && echo Removed ${temp_download_dir} >&2; trap - EXIT; exit' EXIT INT HUP QUIT ILL SEGV TERM XFSZ
trap 'rm -f "${temp_normalized_conf}"; rm -f "${temp_final_conf}"; rm -fr "${temp_download_dir}"; trap - EXIT; exit' EXIT INT HUP QUIT ILL SEGV TERM XFSZ

#
# Main
#

#echo "Temp normalized conf file: ${temp_normalized_conf}
#Temp final conf file: ${temp_final_conf}
#Temp downloads directory: ${temp_download_dir}" | column -t -s :

: > "${temp_normalized_conf}"
test -d "${cache_dir}" || mkdir -p "${cache_dir}"
for provider in ${providers}
do
	if test "${provider}" = "ut1"
	then
		for category in ${ut1_categories}
		do
			url="${ut1_url%/}/${category}.tar.gz"
			cache_compressed="${cache_dir}/ut1_${category}.tar.gz"
			cache="${cache_dir}/ut1_${category}"

			initialize_download_file "${cache_compressed}"

			if download_hosts "${cache_compressed}" "${url}" || ! test -f "${cache}/domains"
			then
			(
				cd "${cache_dir}"

				test -d "${cache}" && rm -rf "${cache}"

				tar xzf "${cache_compressed}"

				mv "${category}" "${cache}"
			) || continue
			fi

			if ! normalize_ut1 < "${cache}/domains" >> "${temp_normalized_conf}"
			then
				printf 'Failed to normalize %s\n' "${cache}" >&2
				logger "${0}: failed to normalize ${cache}."
				continue
			fi
		done
	else
		url="$(eval printf '%s' \$"{${provider}_url}")"
		cache="${cache_dir}/${provider}"

		initialize_download_file "${cache}"

		download_hosts "${cache}" "${url}" || :

		if ! eval normalize_"${provider}" < "${cache}" >> "${temp_normalized_conf}"
		then
			printf 'Failed to normalize %s\n' "${cache}" >&2
			logger "${0}: failed to normalize ${cache}."
			continue
		fi
	fi
done

# Finalize the temp conf
{
	#sed -re 's/\.\" always/" always/g' -e 's/\\"/"/g' ${whitelist_sed_deletions} "${temp_normalized_conf}" \
	sed -re 's/\.\" always/" always/g' -e 's/\\"/"/g' "${temp_normalized_conf}" \
		| grep -v -E "\"(t.co|${grep_ignores})\"" \
		| sort -u \
		| uniq \
		> "${temp_final_conf}"
	chmod 0644 "${temp_final_conf}"
	printf 'Finalized new blacklist for validation\n' >&2
}

if ! is_temp_blacklist_conf_valid
then
	printf 'Validation failed for the new blacklist; discarding\n' >&2
	logger "${0}: validation failed for the new blacklist; discarding."
	exit 1
fi

if ! test -f "${blacklist_conf}"
then
	touch "${blacklist_conf}"
	chmod 0644 "${blacklist_conf}"
	printf 'Initialized blacklist conf before saving new blacklist: %s\n' "${blacklist_conf}" >&2
fi

temp_final_conf_cksum="$(cksum "${temp_final_conf}" > /dev/null 2> /dev/null)" || {
	printf 'Checksum error on the new blacklist; discarding\n' >&2
	logger "${0}: checksum error on the new blacklist; discarding."
	exit 1
}
readonly temp_final_conf_cksum

blacklist_conf_cksum="$(cksum "${blacklist_conf}" > /dev/null 2> /dev/null)" || {
	printf 'Checksum error on the current blacklist\n' >&2
	logger "${0}: checksum error on the current blacklist."
	exit 1
}
readonly blacklist_conf_cksum

if test "${temp_final_conf_cksum}" != "${blacklist_conf_cksum}"
then
	cp "${temp_final_conf}" "${blacklist_conf}"
	printf 'Overwrote the current blacklist with the new blacklist\n' >&2
	#logger "${0}: overwrote the current blacklist with the new blacklist."
	unbound-checkconf > /dev/null
	printf 'unbound-checkconf validated with the new blacklist\n' >&2
	#logger "${0}: unbound-checkconf validated with the new blacklist."
	#unbound-control reload > /dev/null
	printf 'unbound successfully reloaded\n' >&2
	#logger "${0}: unbound successfully reloaded."
	exit 0
else
	printf 'No updates for %s\n' "${blacklist_conf}" >&2
	logger "${0}: no updates for ${blacklist_conf}."
fi

exit 0

