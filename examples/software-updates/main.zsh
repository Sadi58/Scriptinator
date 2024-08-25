#!/usr/bin/env zsh

view_count() {
	local last_time="$(stat "$update_lst" | grep "Modify" | awk '{print $3}' | awk -F. '{print $1}')"
	local interval_sec="$(cat "$HOME/.config/plasma-org.kde.plasma.desktop-appletsrc" | sed -e "0,/^\s*customIcon=.*\s*$/d" -e "/^\s*wheelUpScript=.*\s*$/Q" | grep "timeout=" | awk -F= '{print $2}')"
	local interval_hr="$((interval_sec/60/60))"
	local next_time="$(echo "$last_time" | awk -F: -v interval="$interval_sec" '{ sec=$1*3600+$2*60+$3+interval; printf "%02d:%02d:%02d\n", sec/3600%24, sec/60%60, sec%60 }')"
	if [[ $update_count -gt 0 ]]; then
		kdialog --title "Software Updates" \
			--icon "system-software-update" \
			--passivepopup "<b>${update_count}</b> upgradable packages available as of <b>${last_time}</b><br>- checking <b>every $interval_hr</b> hours<br>- next check at ${next_time}" 5
	else
		kdialog --title "Software Updates" \
			--icon "update-none" \
			--passivepopup "<b>No upgradable packages</b> available as of <b>${last_time}</b> - checking <b>every $interval</b> hours..." 5
	fi
}

view_list() {
	if [[ $update_count -eq 0 ]]; then
		kdialog --title "Software Updates" \
			--icon "update-none" \
			--passivepopup "<big><b>System is up to date!</b></big>"
	elif [[ $update_count -eq 1 ]]; then
		kdialog --title "$update_count Package Upgradable" \
			--icon "system-software-update" \
			--textbox "$update_list" \
			--geometry "430x150+1265+25"
	elif [[ $update_count -le 5 ]]; then
		kdialog --title "$update_count Package Upgradable" \
			--icon "system-software-update" \
			--textbox "$update_list" \
			--geometry "430x300+1265+25"
	elif [[ $update_count -le 15 ]]; then
		kdialog --title "$update_count Package Upgradable" \
			--icon "system-software-update" \
			--textbox "$update_list" \
			--geometry "430x500+1265+25"
	elif [[ $update_count -lt 20 ]]; then
		kdialog --title "$update_count Packages Upgradable" \
			--icon "system-software-update" \
			--textbox "$update_list" \
			--geometry "430x600+1265+25"
	elif [[ $update_count -ge 20 ]]; then
		kdialog --title "$update_count Packages Upgradable" \
			--icon "system-software-update" \
			--textbox "$update_list" \
			--geometry "430x800+1265+25"
	fi
}

menu() {
	if [[ $update_count -eq 0 ]]; then
		kdialog --icon "update-none" --title "Software Updates" --passivepopup "<big><b>System is up to date!</b></big>"
	else
		update_details="$(cat "$update_list")"
		if [[ $update_count -eq 1 ]]; then
			yad --form --title "Software Updates" \
				--image "system-software-update" --image-on-top \
				--columns=2 --separator="|" --item-separator="|" \
				--text="\nWould you like to perform the <b>software update below</b>,\nusing <b>one of the following applications</b>\?\n____________________________________________________________\n\n<i>${update_details}</i>\n" \
				--field="<b>Discover</b>|system-software-update|Perform system software updates offline":FBTN "$HOME/.local/bin/scriptinator_software-updates/main.zsh discover" \
				--field="<b>Apper</b>|svn-update|Launch package manager":FBTN "$HOME/.local/bin/scriptinator_software-updates/main.zsh apper" \
				--field="<b>Konsole</b>|akonadiconsole|Perform software updates in terminal":FBTN "$HOME/.local/bin/scriptinator_software-updates/main.zsh konsole" \
				--button="Close|dialog-ok" \
				--geometry="430+1265+25"
		elif [[ $update_count -le 20 ]]; then
			yad --form --title "Software Updates" \
				--image "system-software-update" --image-on-top \
				--columns=2 --separator="|" --item-separator="|" \
				--text="\nWould you like to perform the <b>${update_count} software updates</b> below,\nusing <b>one of the following applications</b>\?\n____________________________________________________________\n<i>${update_details}</i>" \
				--field="<b>Discover</b>|system-software-update|Perform system software updates offline":FBTN "$HOME/.local/bin/scriptinator_software-updates/main.zsh discover" \
				--field="<b>Apper</b>|svn-update|Launch package manager":FBTN "$HOME/.local/bin/scriptinator_software-updates/main.zsh apper" \
				--field="<b>Konsole</b>|akonadiconsole|Perform software updates in terminal":FBTN "$HOME/.local/bin/scriptinator_software-updates/main.zsh konsole" \
				--button="Close|dialog-ok" \
				--geometry="430+1265+25"
		elif [[ $update_count -gt 20 ]]; then
			update_details="$(cat "$update_list" | head -n 29)"
			yad --form --title "Software Updates" \
				--image "system-software-update" --image-on-top \
				--columns=2 --separator="|" --item-separator="|" \
				--text="\nWould you like to perform the <b>${update_count} software updates</b> available,\nusing <b>one of the following applications</b>\?\n____________________________________________________________\n<i>${update_details}</i>\n<b>.........</b>" \
				--field="<b>View List</b>|format-list-unordered|Display a full list of pending updates":FBTN "$HOME/.local/bin/scriptinator_software-updates/main.zsh view_list" \
				--field="<b>Discover</b>|system-software-update|Perform system software updates offline":FBTN "$HOME/.local/bin/scriptinator_software-updates/main.zsh discover" \
				--field="<b>Apper</b>|svn-update|Launch package manager":FBTN "$HOME/.local/bin/scriptinator_software-updates/main.zsh apper" \
				--field="<b>Konsole</b>|akonadiconsole|Perform software updates in terminal":FBTN "$HOME/.local/bin/scriptinator_software-updates/main.zsh konsole" \
				--button="Close|dialog-ok" \
				--geometry="430+1265+25"
		fi
	fi
}

discover() {
	plasma-discover --mode update
	"$HOME/.local/bin/scriptinator_software-updates/update.zsh"
}

apper() {
	pkexec apper --updates
	"$HOME/.local/bin/scriptinator_software-updates/update.zsh"
}

konsole() {
	sudo konsole -e "zsh -c 'apt full-upgrade; $SHELL'" > /dev/null 2>&1
	sudo apt autoremove --purge
	"$HOME/.local/bin/scriptinator_software-updates/update.zsh"
}

main() {
	if [[ $# -eq 0 ]]; then
		echo "Usage: <script> <function>"
		kdialog --title "Software Updates" --passivepopup "<b>ERROR</b>: <i>function</i> must be entered after the command." --icon "system-software-update" &
		exit 1
	fi

	local func_name=$1
	shift

	if typeset -f $func_name > /dev/null; then
		update_lst="$HOME/.local/share/software-updates-lst.txt"
		update_list="$HOME/.local/share/software-updates-list.txt"
		update_count="$(cat "$update_lst" | wc -l)"
		$func_name
	else
		echo "Error: Function '$func_name' not found"
		kdialog --title "Software Updates" --icon "system-software-update" --passivepopup "<b>ERROR</b>: Function <b><i>$func_name</i></b> not found." &
		exit 1
	fi

}

main "$@"
