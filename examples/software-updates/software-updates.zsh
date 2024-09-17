#!/usr/bin/env zsh

main() {
	if [[ $# -eq 0 ]]; then
		echo "Usage: A function name must be entered after the command."
		kdialog --title "Software Updates" \
			--icon "system-software-update" \
			--passivepopup "A <i>function name</i> must be entered after the command." &
		exit 1
	fi

	func_name="$1"
	shift

	if command -v "$func_name" > /dev/null; then
		bin_dir="$HOME/.local/bin"
		working_dir="$HOME/.local/share"
		update_list="$working_dir/software-updates.lst"
		update_count="$(sed -e '/UPGRADE/d' -e '/INSTALL/d' -e '/^\s*$/d' < "$update_list" | wc -l)"
		"$func_name" "$@"
	else
		echo "Error: Function '$func_name' not found"
		kdialog --title "Software Updates" \
			--icon "system-software-update" \
			--passivepopup "Function <b><i>'$func_name'</i></b> not found." &
		exit 1
	fi

}

update() {
update_lst_pkcon="$working_dir/.software-updates-pkcon.lst"
update_lst_apt="$working_dir/.software-updates-apt.lst"

pkcon get-updates | grep '^Install' | awk '{print $2}' | sed -e 's/\.all$//' -e 's/\.amd64$//' > "$update_lst_pkcon"
apt list --upgradable | sed -e 's/^Listing.*$//' -e 's/^N: .*$//' -e 's/\/.*$//' -e 's/t64$//' -e '/^\s*$/d' > "$update_lst_apt"

if [[ ! -s "$update_lst_pkcon" ]]; then
	sed -e '/^\s*$/d' -e 's/^/- /' "$update_lst_apt" > "$update_list"
elif [[ -s "$update_lst_pkcon" ]]; then
	echo "__________UPGRADE__________" > "$update_list"
	sed -e '/^\s*$/d' -e 's/^/- /' "$update_lst_apt" >> "$update_list"
	echo "__________INSTALL__________" >> "$update_list"
	sed -e '/^\s*$/d' -e 's/^/- /' "$update_lst_pkcon" >> "$update_list"
fi

"$bin_dir/software-status.zsh"
}

view_count() {
	last_time="$(stat "$update_list" | grep "Modify" | awk '{print $3}' | awk -F. '{print $1}')"
	interval_sec="$(sed -e "0,/^\s*customIcon=.*\s*$/d" -e "/^\s*wheelUpScript=.*\s*$/Q" < "$HOME/.config/plasma-org.kde.plasma.desktop-appletsrc" | grep "timeout=" | awk -F= '{print $2}')"
	interval_hr="$((interval_sec/60/60))"
	next_time="$(echo "$last_time" | awk -F: -v interval="$interval_sec" '{ sec=$1*3600+$2*60+$3+interval; printf "%02d:%02d:%02d\n", sec/3600%24, sec/60%60, sec%60 }')"

	if [[ $update_count -gt 0 ]]; then
		kdialog --title "Software Updates" \
			--icon "system-software-update" \
			--passivepopup "<b>$update_count</b> upgradable packages available as of <b>$last_time</b><br>- checking <b>every $interval_hr</b> hours<br>- next check at <b>$next_time</b>"
	else
		kdialog --title "Software Updates" \
			--icon "update-none" \
			--passivepopup "<b>No upgradable packages</b> available as of <b>$last_time</b><br>- checking <b>every $interval_hr</b> hr<br>- next check at <b>$next_time</b>"
	fi
}

view_list() {
	kdialog --title "$update_count Packages Upgradable" \
		--icon "system-software-update" \
		--textbox "$update_list" \
		--geometry "430x800+1265+25"
}

menu() {
	if [[ $update_count -eq 0 ]]; then
		kdialog --title "Software Updates" --icon "update-none" --passivepopup "<big><b>System is up to date!</b></big>"
	else
		update_details="$(cat "$update_list")"
		if [[ $update_count -eq 1 ]]; then
			yad --form --title "Software Updates" \
				--image "system-software-update" --image-on-top \
				--columns=2 --separator="|" --item-separator="|" \
				--text="\nWould you like to perform the <b>software update below</b>,\nusing <b>one of the following applications</b>\?\n____________________________________________________________\n\n<i>$update_details</i>\n" \
				--field="<b>Discover</b>|system-software-update|Perform system software updates offline":FBTN "$bin_dir/software-updates.zsh discover" \
				--field="<b>Apper</b>|svn-update|Launch package manager":FBTN "$bin_dir/software-updates.zsh apper" \
				--field="<b>Konsole</b>|akonadiconsole|Perform software updates in terminal":FBTN "$bin_dir/software-updates.zsh konsole" \
				--button="Close|dialog-ok" \
				--geometry="430+1265+25"
		elif [[ $update_count -le 25 ]]; then
			yad --form --title "Software Updates" \
				--image "system-software-update" --image-on-top \
				--columns=2 --separator="|" --item-separator="|" \
				--text="\nWould you like to perform the <b>$update_count software updates</b> below,\nusing <b>one of the following applications</b>\?\n____________________________________________________________\n<i>$update_details</i>" \
				--field="<b>Discover</b>|system-software-update|Perform system software updates offline":FBTN "$bin_dir/software-updates.zsh discover" \
				--field="<b>Apper</b>|svn-update|Launch package manager":FBTN "$bin_dir/software-updates.zsh apper" \
				--field="<b>Konsole</b>|akonadiconsole|Perform software updates in terminal":FBTN "$bin_dir/software-updates.zsh konsole" \
				--button="Close|dialog-ok" \
				--geometry="430+1265+25"
		elif [[ $update_count -gt 25 ]]; then
			update_details="$(head -n 25 < "$update_list")"
			yad --form --title "Software Updates" \
				--image "system-software-update" --image-on-top \
				--columns=2 --separator="|" --item-separator="|" \
				--text="\nWould you like to perform the <b>$update_count software updates</b> available,\nusing <b>one of the following applications</b>\?\n____________________________________________________________\n<i>$update_details</i>\n<b>.........</b>" \
				--field="<b>View List</b>|format-list-unordered|Display a full list of pending updates":FBTN "$bin_dir/software-updates.zsh view_list" \
				--field="<b>Discover</b>|system-software-update|Perform system software updates offline":FBTN "$bin_dir/software-updates.zsh discover" \
				--field="<b>Apper</b>|svn-update|Launch package manager":FBTN "$bin_dir/software-updates.zsh apper" \
				--field="<b>Konsole</b>|akonadiconsole|Perform software updates in terminal":FBTN "$bin_dir/software-updates.zsh konsole" \
				--button="Close|dialog-ok" \
				--geometry="430+1265+25"
		fi
	fi
}

discover() {
	"$bin_dir/autostart/logout.zsh"
	plasma-discover --mode update
	update
	"$bin_dir/software-status.zsh"
}

apper() {
	apper --updates
	update
	"$bin_dir/software-status.zsh"
}

konsole() {
	konsole -e "zsh -c 'pkcon update; $SHELL'" > /dev/null 2>&1
	update
	"$bin_dir/software-status.zsh"
}

main "$@"
