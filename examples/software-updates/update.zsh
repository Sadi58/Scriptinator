#!/usr/bin/env zsh

update_lst="$HOME/.local/share/software-updates-lst.txt"
update_list="$HOME/.local/share/software-updates-list.txt"

refill_update_list() {
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
}

apt list --upgradable | sed -e "s/^Listing.*$//" -e "s/^N: .*$//" -e "s/\/.*$//g" -e "/^\s*$/d" > "$update_lst"

update_count="$(cat "$update_lst" | sed '/^\s*$/d' | wc -l)"

if [[ $update_count -eq 0 ]] && [[ ! -s $update_list ]]; then
	return
elif [[ $update_count -eq 0 ]] && [[ -s $update_list ]]; then
	truncate -s 0 "$update_list"
	return
elif [[ $update_count -gt 0 ]] && [[ ! -s $update_list ]]; then
	refill_update_list
elif [[ $update_count -gt 0 ]] && [[ -s $update_list ]]; then
	update_lst_content="$(cat "$update_lst"  | sed '/^\s*$/d')"
	update_list_content="$(cat "$update_list" | sed -e 's/^\* //g' -e 's/: .*$//g' -e '/^\s*$/d')"
	if [[ "$update_lst_content" != $update_list_content ]]; then
		refill_update_list
	fi
fi

"$HOME/.local/bin/scriptinator_software-updates/status.zsh"
