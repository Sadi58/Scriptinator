#!/usr/bin/env zsh

status_init() {
	if [[ "$update_count" -eq 0 ]]; then
		echo '{PlasmoidIconStart}update-none{PlasmoidIconEnd}'
		echo '{PlasmoidStatusStart}passive{PlasmoidStatusEnd}'
	elif [[ "$update_count" -lt 10 ]]; then
		echo '{PlasmoidIconStart}update-low{PlasmoidIconEnd}'
		echo '{PlasmoidStatusStart}active{PlasmoidStatusEnd}'
	elif [[ "$update_count" -lt 30 ]]; then
		echo '{PlasmoidIconStart}update-medium{PlasmoidIconEnd}'
		echo '{PlasmoidStatusStart}active{PlasmoidStatusEnd}'
	elif [[ "$update_count" -ge 30 ]]; then
		echo '{PlasmoidIconStart}update-high{PlasmoidIconEnd}'
		echo '{PlasmoidStatusStart}active{PlasmoidStatusEnd}'
	else
		echo '{PlasmoidIconStart}question{PlasmoidIconEnd}'
		echo '{PlasmoidStatusStart}active{PlasmoidStatusEnd}'
	fi
}

status_list() {
	apt list --upgradable > "$update_lst"
	sed -i -e "s/^Listing.*$//" -e "s/^N: .*$//" -e "s/\/.*$//g" -e '/^\s*$/d' "$update_lst"
	if [[ -s "$update_lst" ]]; then
		truncate -s 0 "$update_list"
		while IFS= read -r package_name; do
		description=$(dpkg -l | grep -E "^ii \s*$package_name " | awk -F '[[:space:]]{2,}' '{print $5}')
			if [[ -n "$description" ]]; then
				echo "* $package_name: $description" >> "$update_list"
			else
				echo "* $package_name: [No Description]" >> "$update_list"
			fi
		done < "$update_lst"
		sed -i 's/&/&amp;/g' "$update_list"
	fi
}

status_periodic() {
	echo $my_password | sudo -S apt update
	sleep2
	status_list
	status_init
}

view_count() {
	local time="$(stat "$update_lst" | grep "Modify" | awk -F " " '{print $3}' | awk -F "." '{print $1}')"
	local seconds="$(cat "$HOME/.config/plasma-org.kde.plasma.desktop-appletsrc" | sed -e "0,/^\s*customIcon=.*\s*$/d" -e "/^\s*wheelUpScript=.*\s*$/Q" | grep "timeout=" | awk -F "=" '{print $2}')"
	local hours="$((seconds/60/60))"
	if [[ "$update_count" -gt 0 ]]; then
		kdialog --title "Software Updates" \
			--icon "system-software-update" \
			--passivepopup "<b>${update_count}</b> upgradable packages available as of <b>${time}</b> - checking <b>every $hours</b> hours..." 5
	else
		kdialog --title "Software Updates" \
			--icon "update-none" \
			--passivepopup "<b>No upgradable packages</b> available as of <b>${time}</b> - checking <b>every $hours</b> hours..." 5
	fi
}

view_list() {
	if [[ "$update_count" -eq 0 ]]; then
		kdialog --title "Software Updates" \
			--icon "update-none" \
			--passivepopup "<big><b>System is up to date!</b></big>"
	elif [[ "$update_count" -eq 1 ]]; then
		kdialog --title "${update_count} Package Upgradable" \
			--icon "system-software-update" \
			--textbox "$update_list" \
			--geometry "430x150+1265+25"
	elif [[ "$update_count" -le 5 ]]; then
		kdialog --title "${update_count} Package Upgradable" \
			--icon "system-software-update" \
			--textbox "$update_list" \
			--geometry "430x300+1265+25"
	elif [[ "$update_count" -le 15 ]]; then
		kdialog --title "${update_count} Package Upgradable" \
			--icon "system-software-update" \
			--textbox "$update_list" \
			--geometry "430x500+1265+25"
	elif [[ "$update_count" -lt 20 ]]; then
		kdialog --title "${update_count} Packages Upgradable" \
			--icon "system-software-update" \
			--textbox "$update_list" \
			--geometry "430x600+1265+25"
	elif [[ "$update_count" -ge 20 ]]; then
		kdialog --title "${update_count} Packages Upgradable" \
			--icon "system-software-update" \
			--textbox "$update_list" \
			--geometry "430x800+1265+25"
	fi
}

updater_main() {
	if [[ "$update_count" -eq 0 ]]; then
		kdialog --icon "update-none" --title "Software Updates" --passivepopup "<big><b>System is up to date!</b></big>"
	else
		update_details="$(cat "$update_list")"
		if [[ "$update_count" -eq 1 ]]; then
			yad --form --columns=2 --title "Software Updates" --text="\nWould you like to perform the <b>software update below</b>,\nusing <b>one of the following applications</b>\?\n____________________________________________________________\n\n<i>${update_details}</i>\n" --image "update-low" --image-on-top \
				--field="<b>Discover</b>!system-software-update!Perform system software updates offline :fbtn" "$HOME/.local/bin/scriptinator_software-updates.zsh updater_discover" \
				--field="<b>Apper</b>!svn-update!Launch package manager :fbtn" "$HOME/.local/bin/scriptinator_software-updates.zsh updater_apper" \
				--field="<b>Konsole</b>!akonadiconsole!Perform software updates in terminal :fbtn" "$HOME/.local/bin/scriptinator_software-updates.zsh updater_konsole" \
				--button="Close!dialog-ok" \
				--geometry="430+1265+25"
		elif [[ "$update_count" -le 20 ]]; then
			yad --form --columns=2 --title "Software Updates" --text="\nWould you like to perform the <b>${update_count} software updates</b> below,\nusing <b>one of the following applications</b>\?\n____________________________________________________________\n<i>${update_details}</i>" --image "update-medium" --image-on-top \
				--field="<b>Discover</b>!system-software-update!Perform system software updates offline :fbtn" "$HOME/.local/bin/scriptinator_software-updates.zsh updater_discover" \
				--field="<b>Apper</b>!svn-update!Launch package manager :fbtn" "$HOME/.local/bin/scriptinator_software-updates.zsh updater_apper" \
				--field="<b>Konsole</b>!akonadiconsole!Perform software updates in terminal :fbtn" "$HOME/.local/bin/scriptinator_software-updates.zsh updater_konsole" \
				--button="Close!dialog-ok" \
				--geometry="430+1265+25"
		elif [[ "$update_count" -gt 20 ]]; then
			update_details="$(cat "$update_list" | head -n 29)"
			yad --form --columns=2 --title "Software Updates" --text="\nWould you like to perform the <b>${update_count} software updates</b> available,\nusing <b>one of the following applications</b>\?\n____________________________________________________________\n<i>${update_details}</i>\n<b>.........</b>" --image "update-high" --image-on-top \
				--field="<b>View List</b>!format-list-unordered!Display a full list of pending updates :fbtn" "$HOME/.local/bin/scriptinator_software-updates.zsh view_list" \
				--field="<b>Discover</b>!system-software-update!Perform system software updates offline :fbtn" "$HOME/.local/bin/scriptinator_software-updates.zsh updater_discover" \
				--field="<b>Apper</b>!svn-update!Launch package manager :fbtn" "$HOME/.local/bin/scriptinator_software-updates.zsh updater_apper" \
				--field="<b>Konsole</b>!akonadiconsole!Perform software updates in terminal :fbtn" "$HOME/.local/bin/scriptinator_software-updates.zsh updater_konsole" \
				--button="Close!dialog-ok" \
				--geometry="430+1265+25"
		fi
	fi
}

updater_discover() {
	"$HOME/.local/bin/autostart/logout-script.zsh"
	plasma-discover --mode update
	status_list
	status_init
}

updater_apper() {
	echo $my_password | sudo -S apper --updates
	status_list
	status_init
}

updater_konsole() {
	echo $my_password | sudo -S konsole -e "zsh -c 'apt full-upgrade; $SHELL'" > /dev/null 2>&1
	status_list
	status_init
}

main() {
	if [[ $# -eq 0 ]]; then
		echo "Usage: <script> <function>"
		kdialog --title "Software Updates" --passivepopup "<b>ERROR</b>: <i>function</i> must be entered after the command." --icon "system-software-update" &
		exit 1
	fi

	local func_name=$1
	shift

	if typeset -f "$func_name" > /dev/null; then
		update_lst="$HOME/.local/share/software-updates-lst.txt"
		update_list="$HOME/.local/share/software-updates-list.txt"
		update_count="$(cat "$update_lst" | wc -l)"
		my_password="$(cat "$HOME/.local/bin/.pwd")"
		"$func_name"
	else
		echo "Error: Function '$func_name' not found"
		kdialog --title "Software Updates" --passivepopup "<b>ERROR</b>: Function <b><i>$func_name</i></b> not found." --icon "system-software-update" &
		exit 1
	fi

}

main "$@"
