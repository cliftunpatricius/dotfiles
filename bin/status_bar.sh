#!/bin/sh

#
# UTF-8 Encodings
#

degrees_celsius_symbol="$(printf "\xC2\xB0\x43")"
percent_symbol="$(printf "\x25")"

readonly degrees_celsius_symbol percent_symbol

#
# Timestamp
#

timestamp="$(date '+%a %d-%b-%Y %H:%M')"

readonly timestamp

#
# Hardware
#

cpu_temp="$(sysctl hw.sensors.cpu0.temp0 | cut -d "=" -f 2 | cut -d " " -f 1)"
cpu_speed="$(sysctl hw.cpuspeed | awk -F '=' '{print $2}')"

mem_free="$(top -n | grep Memory | awk '{print $6}')"

if test "${ME_OPERATING_SYSTEM}" = "OpenBSD"
then
	battery_percentage_remaining="$(apm -l)"
	battery_charging_indicator="$(sysctl hw.sensors.acpiac0.indicator0 | grep -c On)"

	if test "${battery_charging_indicator}" -eq "1"
	then
		battery_charging_comment="Charging"
	elif test "${battery_charging_indicator}" -eq "0"
	then
		battery_charging_comment="Draining"
	else
		battery_charging_comment="Unknown"
	fi
elif test "${ME_OPERATING_SYSTEM}" = "Darwin"
then
	battery_percentage_remaining="$(ioreg -c AppleSmartBattery | grep '"CurrentCapacity"' | awk -F ' = ' '{print $2}')"
	battery_charging_indicator="$(ioreg -c AppleSmartBattery | grep '"ChargerConfiguration"' | awk -F ' = ' '{print $2}')"

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

readonly cpu_temp cpu_speed \
	mem_free \
	battery_percentage_remaining battery_charging_indicator battery_charging_comment

#
# Network
#

ssid="$(ifconfig | grep join | sed -En 's/^.*join[[:space:]]+([[:alnum:]]+)[[:space:]]+chan.*$/\1/p')"
iface="$(route -n show | grep default | awk '{print $8}')"
private_ip="$(ifconfig "${iface}" | grep inet | awk '{print $2}')"
public_ip="$(curl -s https://ifconfig.me)"

readonly ssid iface private_ip public_ip

#
# Status Bar
#

printf 'battery: %s (%s) | cpu: %s (%sMHz) | mem_free: %s | network: %s / %s (%s) | %s\n' \
	"${battery_percentage_remaining}${percent_symbol}" "${battery_charging_comment}" \
	"${cpu_temp}${degrees_celsius_symbol}" "${cpu_speed}" \
	"${mem_free}" \
	"${public_ip}" "${private_ip}" "${ssid}" \
	"${timestamp}"

