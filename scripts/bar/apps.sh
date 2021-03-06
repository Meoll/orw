#!/bin/bash

padding=$1
separator="$2"
lines=${@: -1}
offset=$padding
window_name_lenght=20

current_window_id=$(printf "0x%.8x" $(xdotool getactivewindow 2> /dev/null))

if [[ $# -gt 3 ]]; then
	for argument in ${3//,/ }; do
		case $argument in
			a) active=$current_window_id;;
			c) current_desktop=$(xdotool get_desktop);;
			*)
				value=${argument:1}
				property=${argument:0:1}

				[[ $4 == true ]] && separator_color='${Afc:-$fc}'

				case $property in
					l) window_name_lenght=$value;;
					s) app_separator="%{B${separator_color:-\$bg}}%{O$value}";;
					*)
						if [[ $value =~ [0-9] ]]; then
							offset="%{O$value}"
						else
							[[ $value == p ]] && offset=$padding || offset='${inner}'
						fi;;
				esac
		esac
	done
fi

function set_line() {
	fc="\${Afc:-\$fc}"
	frame_width="%{O\${Afw:-\${frame_width-0}}\}"

	frame="%{B$fc\}$frame_width"
	left_frame="%{+u\}%{+o\}$frame"
	right_frame="$frame%{-o\}%{-u\}"
}

[[ $lines != false ]] && set_line

current_window_id=$(printf "0x%.8x" $(xdotool getactivewindow 2> /dev/null))

while read -r window_id window_name; do
	[[ $window_id -eq $current_window_id ]] && current='p' || current='s'

	if [[ ${#window_name} -gt $window_name_lenght ]]; then
		window_name="${window_name:0:$window_name_lenght}"
		#[[ $current == s ]] && window_name+='..'
		window_name+='..'
	fi

	#window_name="${padding}${window_name}${padding}"
	window_name="${offset}${window_name}${offset}"

	if [[ $window_id ]]; then
		bg="\${A${current}bg:-\${Asbg:-\$${current}bg}}"
		fg="\${A${current}fg:-\${Asfg:-\$${current}fg}}"

		window="%{A:wmctrl -ia $window_id:}$bg$fg${padding}${window_name//\"/\\\"}${padding}%{A}"

		if [[ $lines == single ]]; then
			if [[ $current == p ]]; then
				[[ ! $separator =~ ^[s%] ]] && window="\$start_line$window\$end_line" ||
					window="%{U$fc}\${start_line:-$left_frame}$window\${end_line:-$right_frame}"
			else
				window="%{-o}%{-u}$window"
			fi

			#window="%{U$fc}\${start_line:-$left_frame}$window\${end_line:-$right_frame}"
		fi

		apps+="$window$app_separator"
	fi
done <<< $(wmctrl -l | awk '$1 ~ /'$active'/ && !/ (input|image_preview)/ && $2 ~ /^'${current_desktop-[0-9]}'/ {
		print $1, (NF > 3) ? substr($0, index($0, $4)) : "no name" }')

#~/.orw/scripts/notify.sh "s: $separator"

[[ $app_separator ]] && apps=${apps%\%*}

if [[ $lines != false ]]; then
	#~/.orw/scripts/notify.sh "s: $separator"
	case $separator in
		[ej]*)
			[[ $separator =~ j ]] &&
				apps+='$start_line'
			apps+="${separator:1}";;
		s*) apps="%{U$fc}\${start_line:-$left_frame}$apps\$start_line${separator:2}";;
		#e*) launchers+="\${end_line:-$right_frame}%{B\$bg}${separator:1}";;
		#e*) launchers+="${separator:1}";;
		*) apps="%{U$fc}\${start_line:-$left_frame}$apps\${end_line:-$right_frame}%{B\$bg}$separator";;
	esac

	#launchers="%{U$fc}\${start_line:-$left_frame}$launchers\${end_line:-$right_frame}"
else
	apps+="%{B\$bg}$separator"
fi

#case $separator in
#	s*) separator="${separator:2}";;
#	[ej]*) separator="${separator:1}";;
#esac

#[[ $app_separator ]] && windows=${windows%\%*}
#[[ $windows && $lines == true ]] && windows="%{U$fc}\${start_line:-$left_frame}$windows\${end_line:-$right_frame}"
#~/.orw/scripts/notify.sh "W: $windows"

#[[ $windows ]] && echo -e "$windows%{B\$bg}\$separator"
echo -e "$apps"
