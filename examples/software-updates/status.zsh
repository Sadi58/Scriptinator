#!/usr/bin/env zsh

update_lst="$HOME/.local/share/software-updates-lst.txt"
update_count="$(cat "$update_lst" | sed '/^\s*$/d'  | wc -l)"

if [[ $update_count -eq 0 ]]; then
	echo '{PlasmoidIconStart}update-none{PlasmoidIconEnd}'
	echo '{PlasmoidStatusStart}passive{PlasmoidStatusEnd}'
elif [[ $update_count -lt 10 ]]; then
	echo '{PlasmoidIconStart}update-low{PlasmoidIconEnd}'
	echo '{PlasmoidStatusStart}active{PlasmoidStatusEnd}'
elif [[ $update_count -lt 30 ]]; then
	echo '{PlasmoidIconStart}update-medium{PlasmoidIconEnd}'
	echo '{PlasmoidStatusStart}active{PlasmoidStatusEnd}'
elif [[ $update_count -ge 30 ]]; then
	echo '{PlasmoidIconStart}update-high{PlasmoidIconEnd}'
	echo '{PlasmoidStatusStart}active{PlasmoidStatusEnd}'
else
	echo '{PlasmoidIconStart}question{PlasmoidIconEnd}'
	echo '{PlasmoidStatusStart}active{PlasmoidStatusEnd}'
fi
