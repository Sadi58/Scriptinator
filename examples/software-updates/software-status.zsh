#!/usr/bin/env zsh

update_list="$HOME/.local/share/software-updates.lst"
update_count="$(sed -e '/UPGRADE/d' -e '/INSTALL/d' -e '/^\s*$/d' < "$update_list" | wc -l)"

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
