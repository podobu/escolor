#!/usr/bin/env bash

# Copyright © 2024 Jesús Arenas

# This program is free software: you can redistribute it and/or modify it under the terms
# of the GNU General Public License as published by the Free Software Foundation, either
# version 3 of the License, or (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
# without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
# See the GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License along with this program.
# If not, see <https://www.gnu.org/licenses/>.

print_usage() {
	echo -n "\
Usage: $(basename $0) [OPTIONS... [STRINGS..]]

Print a string containing the escape sequence that produces ANSI colors.

Options:
  -e, --escape                Print the escaped string.
  -n, --newline               Ouput a trailing newline (default).
  -E, --no-escape             Print the escape sequence string (default).
  -N, --no-newline            Do not ouput a trailing newline.

  -c, --color COLOR           Set foreground color sequence for COLOR.
  -g, --background COLOR      Set background color sequence for COLOR.
  -b, --bold                  Set bold sequence.
  -i, --italic                Set italic sequence.
  -u, --underline             Set underline sequence.
  -d, --double-underline      Set double underline sequence.
  -o, --overline              Set overline sequence.
  -t, --crossed-out           Set crossed out sequence.
  -k, --blink                 Set blink sequence.
  -s, --swap                  Set foreground-background swap sequence.

  -C, --no-color              Reset foreground color sequence.
  -G, --no-background         Reset background color sequence.
  -B, --no-bold               Reset bold sequence.
  -I, --no-italic             Reset italic sequence.
  -U, --no-underline          Reset single or double underline sequence.
  -O, --no-overline           Reset overline sequence.
  -T, --no-crossed-out        Reset crossed out sequence.
  -K, --no-blink              Reset blink sequence.
  -S, --no-swap               Reset foreground-background swap sequence.
  -r, --reset                 Reset all effects sequence.

  -h, --help                  Print this help and exit.
  -v, --version               Print version and other info and exit.

  Options are evaluated sequentially.

Available colors:
  Colors can be named, 8-bit, hexadecimal and RGB.

  A named color must be one of the following names:
    BLACK, RED, GREEN, YELLOW, BLUE, MAGENTA, CYAN, WHITE.
    BBLACK, BRED, BGREEN, BYELLOW, BBLUE, BMAGENTA, BCYAN, BWHITE.
  The case of the names of colors is ignored: red = RED

  A 8-bit color must be a number between 0 and 255 (one byte).

  Hexadecimal colors are of the form:
    #RRGGBB.
  The '#' symbol is optional.
  The case of hexadecimal colors is ignored: ffffff = FFFFFF

  RGB colors are of the form:
    RRR,GGG,BBB
  'RRR', 'GGG' and 'BBB' are numbers between 0 and 255.

Examples:
  Print the escape sequence:
    $(basename $0) --color RED --background BLUE
    $(basename $0) -c RED -g BLUE
    $(basename $0) -cg RED BLUE
  \\x1b[31;44m
    $(basename $0) -gc RED BLUE
  \\x1b[41;34m

  Print the string with the escape sequence:
    $(basename $0) -cg RED BLUE \"HELLO WORLD\"
  \\x1b[31;44mHELLO WORLD\\x1b[m

  Print the escaped string with colors:
    $(basename $0) --escape -cg RED BLUE \"HELLO WORLD\"
  HELLO WORLD

  Print the escaped string with words of different colors:
    $(basename $0) -ecg RED BLUE HELLO -r ' ' -cg CYAN MAGENTA WORLD
  HELLO WORLD

  Print the escaped string with colors:
    $(basename $0) -ecg RED BLUE --this-is-not-an-option
  --this-is-not-an-option

  If you want to give a string that is equal to an option, it must be
  enclosed in quotation marks (for the shell) and start with a backslash
  (for the program). Single quotes are preferred than double quotes.
  Print the escaped string \"-E\" with colors:
    $(basename $0) -ecg RED BLUE '\\-E'
  -E

  In fact, any string starting with backslash will strip the backslash:
    $(basename $0) -ecg RED BLUE '\\HELLO WORLD'
  HELLO WORLD
    $(basename $0) -ecg RED BLUE '\\\\HELLO WORLD'
  \\HELLO WORLD

  Print the escaped string with hexadecimal colors:
    $(basename $0) -ecg cc0000 \\#2986cc \"HELLO WORLD\"
    $(basename $0) -ecg '#cc0000' \"#2986cc\" \"HELLO WORLD\"
  HELLO WORLD

  Print the escaped string with RGB colors:
    $(basename $0) -ecg 255,0,0 1,99,255 \"HELLO WORLD\"
  HELLO WORLD

Exit status: 
  Returns 1 if an invalid color is given.
  Returns 0 otherwise.

This program is licensed under GPL-3.0-or-later.
"
	exit 0
}

print_about() {
	echo -n "\
escolor 1.0.0
Copyright © 2024 Jesús Arenas
Official repository: https://github.com/podobu/escolor
License GPLv3+: GNU GPL version 3 or later <https://gnu.org/licenses/gpl.html>.
"
	exit 0
}

parse_options() {
	declare -ga PRSOPT
	declare parameters_with_values
	declare option
	declare -i value_position
	declare -i i=0

	# Capturing short options with values
	while [ "$1" != "--" -a $# -gt 0 ]; do
		parameters_with_values+="$1"
		shift
	done
	shift

	swv="$(cut --delimiter ':' --fields '1' <<< "$parameters_with_values")"
	lwv="$(cut --delimiter ':' --fields '1' --complement <<< "$parameters_with_values")"

	# Parsing
	while [ $# -gt 0 ]; do

		value_position=2

		if [ "${1:0:1}" = '-' -a ${#1} -gt 1 ]; then
			if [ "${1:1:1}" = '-' -a ${#1} -gt 2 ]; then
				PRSOPT[i]="$1"
				if grep --word-regexp --fixed-strings --quiet "${1:2}" <<< "$lwv"; then
					PRSOPT[++i]="${!value_position}"
					(( ++value_position ))
				fi
			else
				for (( j = 1; j < ${#1}; j++, i++ )) do
					option="${1:j:1}"
					PRSOPT[i]="-$option"
					if grep --fixed-strings --quiet "$option" <<< "$swv"; then
						PRSOPT[++i]="${!value_position}"
						(( ++value_position ))
					fi
				done
			fi
		else
			PRSOPT[i]="$1"
		fi

		i=++i
		if [ $value_position -gt $# ]; then
			shift $#
		else
			shift $((--value_position))
		fi

	done
}

throw_color_error() {
	local color
	if [ -n "$1" ]; then
		color="'${1}'"
	else
		color="NO COLOR GIVEN"
	fi
	echo "$(basename $0): Invalid color given: $color. See usage with -h or --help." >&2
	exit 1
}

get_color() {
	declare -u color="${1^^}"
	declare -i background="${2:+"10"}"
	case "$color" in
		'BLACK') color="$((background+30))" ;;
		'RED') color="$((background+31))" ;;
		'GREEN') color="$((background+32))" ;;
		'YELLOW') color="$((background+33))" ;;
		'BLUE') color="$((background+34))" ;;
		'MAGENTA') color="$((background+35))" ;;
		'CYAN') color="$((background+36))" ;;
		'WHITE') color="$((background+37))" ;;
		'BBLACK') color="$((background+90))" ;;
		'BRED') color="$((background+91))" ;;
		'BGREEN') color="$((background+92))" ;;
		'BYELLOW') color="$((background+93))" ;;
		'BBLUE') color="$((background+94))" ;;
		'BMAGENTA') color="$((background+95))" ;;
		'BCYAN') color="$((background+96))" ;;
		'BWHITE') color="$((background+97))" ;;
		*)
			# 8 bit color
			if [[ "$color" =~ ^[[:digit:]]{1,3}$ ]] && [ $color -lt 256 ]; then
				color="$((background+38));5;${color}"
			# hex color
			elif [[ "$color" =~ ^#?[[:digit:]A-F]{6}$ ]];then
				if [ "${color:0:1}" = "#" ]; then color="${color:1}"; fi
				r=$((0X${color:0:1}*16+0X${color:1:1}))
				g=$((0X${color:2:1}*16+0X${color:3:1}))
				b=$((0X${color:4:1}*16+0X${color:5:1}))
				color="$((background+38));2;${r};${g};${b}"
			# rgb color
			elif [[ "$color" =~ ^[[:digit:]]{1,3},[[:digit:]]{1,3},[[:digit:]]{1,3}$ ]] &&\
			r="$(echo "$color" | cut --delimiter=, --fields=1)" &&\
			g="$(echo "$color" | cut --delimiter=, --fields=2)" &&\
			b="$(echo "$color" | cut --delimiter=, --fields=3)" &&\
			[ $r -lt 256 ] && [ $g -lt 256 ] && [ $b -lt 256 ]; then
				color="$((background+38));2;${r};${g};${b}"
			else
				return 1
			fi
			;;
	esac
	echo "$color"
}

parse_options "cg" -- "$@"
set -- "${PRSOPT[@]}"

output_string="\x1b["

while [ $# -gt 0 ]; do

	case "$1" in
		'-h' | '--help') print_usage ;;
		'-v' | '--version') print_about ;;

		'-e' | '--escape') escape=1 ;;
		'-n' | '--newline') unset no_newline ;;
		'-E' | '--no-escape') unset escape ;;
		'-N' | '--no-newline') no_newline=1 ;;

		'-c' | '--color')
			color=$(get_color "$2") || throw_color_error "$2"
			output_string+="${color};"
			shift
			;;
		'-g' | '--background')
			if [ -n "$2" ]; then
				color=$(get_color "$2" 1) || throw_color_error "$2"
				output_string+="${color};"
				shift
			else
				throw_color_error
			fi
			;;
		'-b' | '--bold') output_string+="1;" ;;
		'-i' | '--italic') output_string+="3;" ;;
		'-u' | '--underline') output_string+="4;" ;;
		'-d' | '--double-underline') output_string+="21;" ;;
		'-o' | '--overline') output_string+="53;" ;;
		'-t' | '--crossed-out') output_string+="9;" ;;
		'-k' | '--blink') output_string+="5;" ;;
		'-s' | '--swap') output_string+="7;" ;;

		'-C' | '--no-color') output_string+="39;" ;;
		'-G' | '--no-background') output_string+="49;" ;;
		'-B' | '--no-bold') output_string+="22;" ;;
		'-I' | '--no-italic') output_string+="23;" ;;
		'-U' | '--no-underline') output_string+="24;" ;;
		'-O' | '--no-overline') output_string+="55;" ;;
		'-T' | '--no-crossed-out') output_string+="29;" ;;
		'-K' | '--no-blink') output_string+="25;" ;;
		'-S' | '--no-swap') output_string+="27;" ;;
		'-r' | '--reset') output_string+="0;" ;;
		*) 
			#                                        end ; -> m      end \x1b[ -> ""                  begin \ -> ""   any \ -> \\
			output_string="$(echo "$output_string" | sed 's/;$/m/' | sed 's/\\x1b\[$//')$(echo "$1" | sed 's/^\\//' | sed 's/\\/\\\\/')\x1b["
			;;
	esac

	shift 
done # while

echo ${no_newline:+"-n"} ${escape:+"-e"} "$(echo "$output_string" | sed 's/;$//')m"
