#!/bin/bash

function show_status() {
	[[ $1 =~ (true|yes) ]] && local status=yes
	sed -i "/^statusbar_visibility/ s/\".*/\"${status:-no}\"/" ~/.orw/dotfiles/.config/ncmpcpp/config{,_cover_art}
}

function show_progessbar() {
	if [[ $1 =~ (true|yes) ]]; then
		vis_bar='   '
		vis_status="no"
		list_bar='━━━'
		list_status="yes"
	else
		vis_bar='━━━'
		vis_status="yes"
		list_bar='   '
		list_status="no"
	fi

	sed -i "/^progressbar_look/ s/\".*/\"$vis_bar\"/" ~/.config/ncmpcpp/config_visualizer
	sed -i "/^progressbar_look/ s/\".*/\"$list_bar\"/" ~/.config/ncmpcpp/config{,_cover_art}
	#sed -i "/^statusbar_visibility/ s/\".*/\"$vis_status\"/" ~/.ncmpcpp/config_visualizer
	#sed -i "/^statusbar_visibility/ s/\".*/\"$list_status\"/" ~/.ncmpcpp/config{,_cover_art}
}

function get_cover_properties() {
	ratio=${ratio-90}
	padding=$(sed -n 's/[^0-9]*\([0-9]\+\).*/\1/p' ~/.config/gtk-3.0/gtk.css 2> /dev/null)

	if [[ ! $width && ! $height ]]; then
		read width height <<< $(wmctrl -lG | \
		awk '$NF == "ncmpcpp_with_cover_art" { print $5 - ('$padding' * 2), $6 - ('$padding' * 2) }')
	fi

	sed -i "/^execute/ s/[0-9]\+/$ratio/" ~/.orw/dotfiles/.config/ncmpcpp/config_cover_art

	read s x y r <<< $(awk 'BEGIN { \
		r = 0.'$ratio'; w = '$width'; h = '$height'; \
		if (h < 300 && r >= 0.8) { x = int('$padding' + (h * (1 - r)) / 2); div = h; a = 1 } \
		else { x = ('$padding' + 2); div = int(h * r); a = 1 }; \
		s = int(h * r); y = int((h - s + ('$padding' / 2)) / 2); w = int(100 - (100 / (w / div)) - a); print s, x, y, w}')
}

function draw_cover_art() {
	cover=$(~/.orw/scripts/get_cover_art.sh)

	[[ -f "$cover" ]] && echo -e "0;1;$x;$y;$s;$s;;;;;$cover\n3;" | /usr/lib/w3m/w3mimgdisplay || 
		$base_command send -t ncmpcpp_with_cover_art:0.0 'clear' Enter
	exit
}

base_command='TERM=xterm-256color tmux -S /tmp/tmux_hidden -f ~/.config/tmux/tmux_hidden.conf'

while getopts :pvscdaRVCP:S:L:D:r:w:h:i flag; do
	case $flag in
		p)

			#[[ $V ]] && layout="move -h 2/3 -v 2/4 resize -h 1/3 -v 1/4" ||
			#	layout="move -v 3/7 -h 8/12 resize -v 3/7 -e r -h 3/4 -l +21 -r +21"

			width=${width:-500}
			height=${height:-350}
			title=ncmpcpp_playlist

			[[ ! $pre ]] && pre="~/.orw/scripts/windowctl.sh "

			[[ $V ]] && edge=b orientation=-v reverse_orientation=h ||
				edge=r orientation=-h reverse_orientation=v

			layout="move -e $edge $orientation 1/2 -c $reverse_orientation"
			pre+="$layout && sleep 0.1 > /dev/null"

			command='new -s playlist ncmpcpp';;
		v)
			#width=70
			#height=70
			title=visualizer
			progressbar=yes

			[[ ! $pre ]] && pre="~/.orw/scripts/windowctl.sh "

			#[[ $V ]] && layout="move -h 2/3 -v 3/4 resize -h 1/3 -v 1/4" progressbar=yes ||
			#	layout="move -v 3/7 -h 2/4 resize -v 3/7 -h 1/3"

			if [[ $V ]]; then
				width=${width:-500}
				height=${height:-150}
				edge=t orientation=-v reverse_orientation=h progressbar=yes
			else
				width=${width:-250}
				height=${height:-350}
				edge=l orientation=-h reverse_orientation=v
			fi

			layout="move -e $edge $orientation 2/2 -c $reverse_orientation"

			pre+="$layout && sleep 0.1 > /dev/null"

			command='new -s visualizer cava'
			show_progessbar ${progressbar-no};;
		s)
			width=${width-450}
			height=${height-600}
			title=ncmpcpp_split

			#progressbar=no
			show_status no

			command='new -s split ncmpcpp \; splitw -p 20 cava \; selectp -U';;
		c)
			[[ $@ =~ -i ]] && width=${width-550} height=${height-200}
			title=ncmpcpp_with_cover_art

			get_cover_properties
			show_progessbar yes

			command="new -s ncmpcpp_with_cover_art \; splitw -h -p $r ncmpcpp -c ~/.orw/dotfiles/.config/ncmpcpp/config_cover_art";;
		d)
			~/.orw/scripts/ncmpcpp.sh $display $V -v -i
			until [[ $(wmctrl -l | awk '$NF ~ "visualizer"') ]]; do continue; done
			~/.orw/scripts/ncmpcpp.sh $display $V -p -i
			exit;;
		C) get_cover_properties && draw_cover_art;;
		[PS])
			[[ $flag == S ]] && show_status $OPTARG || show_progessbar $OPTARG
			(($# + 1 == OPTIND)) && exit 0;;
		#S) show_status $OPTARG && exit;;
		#P) show_progessbar $OPTARG && exit;;
		L) pre="~/.orw/scripts/windowctl.sh $OPTARG";;
		D)
			display="-D $OPTARG"
			pre="~/.orw/scripts/windowctl.sh -d $OPTARG move";;
		V) V=-V;;
		R)
			ratio=$(sed -n 's/^execute.*[^0-9]\([0-9]\+\).*/\1/p' ~/.orw/dotfiles/.config/ncmpcpp/config_cover_art)
			command="send -t ncmpcpp_with_cover_art:0.0 'clear && sleep 0.1 && $0 -r $ratio -C' Enter";;
		r) ratio=$OPTARG;;
		a)
			for session in $(tmux -S /tmp/tmux_hidden ls 2> /dev/null | awk -F ':' '{ print $1 }'); do
				case $session in
					*play*) pane=0;;
					*cover*) pane=1;;
					*split*) pane=1;;
					visualizer) pane=0;;
				esac

				tmux -S /tmp/tmux_hidden respawn-pane -k -t ${session}:0.$pane
			done && exit;;
		w) width=$OPTARG;;
		h) height=$OPTARG;;
		i)
			if ! xdotool search --name "'${title-ncmpcpp}'"; then
				width=${width:-900}
				height=${height:-500}

				[[ $title ]] || show_status yes

				~/.orw/scripts/set_class_geometry.sh -c size -w $width -h $height

				termite -t ${title-ncmpcpp} --class=custom_size \
					-e "bash -c '~/.orw/scripts/execute_on_terminal_startup.sh ${title-ncmpcpp} \
					\"${pre:-$0 -P ${progressbar-yes}} && $base_command ${command-new -s ncmpcpp ncmpcpp}\"'" &> /dev/null &
				exit
			fi
		esac
done

show_status yes
show_progessbar ${progressbar-yes}
eval "$base_command ${command-new -s ncmpcpp ncmpcpp}"
