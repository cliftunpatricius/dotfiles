#!/bin/sh

#
# This will be run to set the right-hand `tmux` status bar.
#
# Until I figure out how to have `tmux` inherit my environment
# variables, set again here as needed.
#

operating_system="$(uname -s)"

readonly operating_system

#
# UTF-8 Encodings
#

degrees_celsius_symbol="$(printf "\xC2\xB0\x43")"
percent_symbol="$(printf "\x25")"

readonly degrees_celsius_symbol percent_symbol

#
# Timestamp
#

timestamp="$(date '+%Y%m%d %a %H:%M')"
uptime="$(
	uptime |
	awk -F ',' '{print $1}' |
	sed -E 's/[[:space:]]+/ /g' |
	sed -En 's/^.+(up .+)$/\1/p'
)"

readonly timestamp uptime

#
# Hardware
#

# Normalize the `sysctl` output to OpenBSD format via `sed`
cpu_count="$(
	sysctl hw.ncpu |
	sed -E 's/:[[:space:]]+/=/g' |
	awk -F '=' '{print $2}'
)"

if test "${operating_system}" = "OpenBSD"
then
	cpu_temp="$(
		# Ignore error if sensor does not exist
		sysctl hw.sensors.cpu0.temp0 2>/dev/null |
		cut -d "=" -f 2 |
		cut -d " " -f 1
	)"

	mem_free="$(top -n | grep Memory | awk '{print $6}')"

	battery_percentage_remaining="$(apm -l)"
	battery_charging_indicator="$(
		sysctl hw.sensors.acpiac0.indicator0 |
		grep -c On
	)"

	if test "${battery_charging_indicator}" -eq "1"
	then
		battery_charging_comment="Charging"
	elif test "${battery_charging_indicator}" -eq "0"
	then
		battery_charging_comment="Draining"
	else
		battery_charging_comment="Unknown"
	fi
elif test "${operating_system}" = "Darwin"
then
	cpu_temp=""

	mem_free="$(top -l 1 | grep PhysMem | awk '{print $8}')"

	battery_percentage_remaining="$(
		ioreg -c AppleSmartBattery |
		grep '"CurrentCapacity"' |
		awk -F ' = ' '{print $2}'
	)"
	battery_charging_indicator="$(
		ioreg -c AppleSmartBattery |
		grep '"ChargerConfiguration"' |
		awk -F ' = ' '{print $2}'
	)"

	if test "${battery_charging_indicator}" -gt "0"
	then
		battery_charging_comment="Charging"
	elif test "${battery_charging_indicator}" -eq "0"
	then
		battery_charging_comment="Draining"
	else
		battery_charging_comment="Unknown"
	fi
fi

readonly cpu_count \
	cpu_temp \
	mem_free \
	battery_percentage_remaining \
	battery_charging_indicator \
	battery_charging_comment

#
# Network
#

if test "${operating_system}" = "OpenBSD"
then
	iface="$(route -n show | grep default | awk '{print $8}')"
	ssid="$(
		ifconfig "${iface}" |
		grep join |
		sed -En 's/^.*join[[:space:]]+([[:alnum:]]+)[[:space:]]+chan.*$/\1/p'
	)"
elif test "${operating_system}" = "Darwin"
then
	iface="$(
		route -n get default |
		grep -E '^[[:space:]]+interface:[[:space:]]+' |
		awk '{print $2}'
	)"
	ssid=""
fi

public_ip="$(curl -s https://ifconfig.me)"
private_ip="$(
	ifconfig "${iface}" |
	grep -E '^[[:space:]]+inet[[:space:]]+[[:digit:]]+' |
	awk '{print $2}'
)"

readonly iface ssid public_ip private_ip

#
# Status Bar
#

# Test out the shorter one for a while
if test "$(tput cols)" -gt "0"
then
	printf '%s (%s) | %s | %s (%s) | %s\n' \
		"${battery_percentage_remaining}${percent_symbol}" \
		"${battery_charging_comment}" \
		"${mem_free}" \
		"${private_ip}" \
		"${ssid}" \
		"${timestamp}"
else
	printf '%s (%s) | %s (%s) | %s | %s / %s (%s) | %s | %s\n' \
		"${battery_percentage_remaining}${percent_symbol}" \
		"${battery_charging_comment}" \
		"${cpu_count}" \
		"${cpu_temp}${degrees_celsius_symbol}" \
		"${mem_free}" \
		"${public_ip}" \
		"${private_ip}" \
		"${ssid}" \
		"${uptime}" \
		"${timestamp}"
fi
