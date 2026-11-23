#!/bin/sh

gnome_swap_caps_and_lctl()
{
	gsettings get org.gnome.desktop.input-sources xkb-options |
		grep -Eq 'caps:ctrl_modifier' || {
		gsettings set org.gnome.desktop.input-sources xkb-options \
			"['caps:ctrl_modifier']"
	}
}

gnome_set_color_scheme()
{
	test "'${1}'" = "$(gsettings get org.gnome.desktop.interface color-scheme)" || {
		printf 'Setting color scheme to '%s' ...\n' "${1}"
		gsettings set org.gnome.desktop.interface color-scheme "${1}"
	}
}
gnome_set_dark_mode() { gnome_set_color_scheme "prefer-dark"; }
gnome_set_light_mode() { gnome_set_color_scheme "prefer-light"; }

gnome_enable_night_light()
{
	test "true" = "$(gsettings get org.gnome.settings-daemon.plugins.color night-light-enabled)" || {
		printf 'Enabling Night Light ...\n'
		gsettings set org.gnome.settings-daemon.plugins.color night-light-enabled true
	}
}

gnome_schedule_night_light_from()
{
	test "${1}" = "$(gsettings get org.gnome.settings-daemon.plugins.color night-light-schedule-from)" || {
		printf 'Sheduling Night Light from: %s ...\n' "${1}"
		gsettings set org.gnome.settings-daemon.plugins.color night-light-schedule-from "${1}"
	}
}

gnome_schedule_night_light_to()
{
	test "${1}" = "$(gsettings get org.gnome.settings-daemon.plugins.color night-light-schedule-to)" || {
		printf 'Sheduling Night Light to: %s ...\n' "${1}"
		gsettings set org.gnome.settings-daemon.plugins.color night-light-schedule-to "${1}"
	}
}
