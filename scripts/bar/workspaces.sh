#!/bin/bash

workspace_count=$(xdotool get_num_desktops)
current_workspace=$(($(xdotool get_desktop) + 1))

offset=$3
padding=$1
separator="$2"
single_line=${@: -1}

function set_line() {
	fc="\${Wfc:-\$fc}"
	frame="%{B$fc\}$frame_width"
	left_frame="%{+u\}%{+o\}$frame"
	right_frame="$frame%{-o\}%{-u\}"
}

[[ $single_line == false ]] && format_delimiter=' '

for workspace_index in $(seq $workspace_count); do
	[ $workspace_index -eq $current_workspace ] && current=p || current=s

	for arg in ${4//,/ }; do
		case $arg in
			o*)
				value=${arg:1}

				if [[ $value =~ [0-9] ]]; then
					offset="%{O$value}"
				else
					[[ $value == p ]] && offset=$padding || offset='$inner'
				fi;;
			[cr]) [[ ! $flags =~ $arg ]] && flags+=$arg;;
			s*) workspace_separator="\$bsbg%{O${arg:1}}";;
			l) label="${padding}$(wmctrl -d | awk '$1 == '$((workspace_index - 1))' \
				{ wn = $NF; if(wn ~ /^[0-9]+$/) { if(wn > 1) tc = wn - 1; wn = "tmp" tc }; print wn }')${padding}";;
			n) label="$offset$workspace_index$offset";;
			b*) ((${#arg} > 1)) && label=%{O${arg:1}} || label=$offset;;
			*)
				case ${arg: -1} in
					d) icon_type=dot;;
					h) icon_type=half;;
					e) icon_type=empty;;
					*) icon_type=default;;
				esac

				icon="$(sed -n "s/Workspace_${icon_type}_${current}_icon=//p" ${0%/*}/icons)"
				#~/.orw/scripts/notify.sh "Workspace_${icon_type}_${current}_icon"
				#:icon="${current}_icon"
				#~/.orw/scripts/notify.sh "$workspace_index: $offset"
				#~/.orw/scripts/notify.sh "$workspace_index: $offset"
				label="$offset$icon$offset";;
		esac
	done

	bg="\${W${current}bg:-\${Wsbg:-\$${current}bg}}"
	fg="\${W${current}fg:-\${Wsfg:-\$${current}fg}}"

	[[ $fbg ]] || fbg=$bg

	command="wmctrl -s $((workspace_index - 1)) \&\& ~/.orw/scripts/barctl.sh -b wss -k \&"
	[[ $flags ]] && command+=" ~/.orw/scripts/wallctl.sh -$flags \&"
	#~/.orw/scripts/notify.sh "$command"
	workspace="%{A:$command:}$bg$fg$label%{A}"

	if [[ $single_line == true ]]; then
		if [[ $current == p ]]; then
			set_line

			[[ ! $separator =~ ^[s%] ]] && workspace="\$start_line$workspace\$end_line" ||
				workspace="%{U$fc}\${start_line:-$left_frame}$workspace\${end_line:-$right_frame}"
		else
			workspace="%{-o}%{-u}$workspace"
		fi
	fi

	((workspace_index < workspace_count)) && workspace+="$workspace_separator"

	workspaces+="$workspace"
done

[[ $4 =~ i ]] && workspaces="$fbg${padding}${workspaces%\%*}${padding}"

workspaces="%{A2:~/.orw/scripts/barctl.sh -b wss:}\
%{A4:wmctrl -s $((((current_workspace + workspace_count - 2) % workspace_count))):}\
%{A5:wmctrl -s $((current_workspace % workspace_count)):}\
$workspaces%{A}%{A}%{A}"

if [[ $single_line == true ]]; then
	#~/.orw/scripts/notify.sh "s: $separator"
	case $separator in
		[ej]*)
			[[ $separator =~ j ]] &&
				workspaces+='$start_line'
			workspaces+="${separator:1}";;
		s*) workspaces="%{U$fc}\${start_line:-$left_frame}$workspaces\$start_line${separator:2}";;
		#e*) launchers+="\${end_line:-$right_frame}%{B\$bg}${separator:1}";;
		#e*) launchers+="${separator:1}";;
		*) workspaces="%{U$fc}\${start_line:-$left_frame}$workspaces\${end_line:-$right_frame}%{B\$bg}$separator";;
	esac

	#launchers="%{U$fc}\${start_line:-$left_frame}$launchers\${end_line:-$right_frame}"
else
	workspaces+="%{B\$bg}$format_delimiter$separator"
fi

echo -e "$workspaces"

#case $separator in
#	s*) separator="${separator:2}";;
#	[ej]*) separator="${separator:1}";;
#esac

#echo -e "%{A2:~/.orw/scripts/barctl.sh -b wss:}\
#%{A4:wmctrl -s $((((current_workspace + workspace_count - 2) % workspace_count))):}\
#%{A5:wmctrl -s $((current_workspace % workspace_count)):}\
#$workspaces%{A}%{A}%{A}%{B\$bg}$format_delimiter$separator"
