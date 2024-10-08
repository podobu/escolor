#!/usr/bin/env python3

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

from sys import argv, stderr
from os.path import basename
from re import search

def print_usage() -> None:
	print(f"""\
Usage: {basename(__file__)} [OPTIONS... [STRINGS..]]

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
    {basename(__file__)} --color RED --background BLUE
    {basename(__file__)} -c RED -g BLUE
    {basename(__file__)} -cg RED BLUE
  \\x1b[31;44m
    {basename(__file__)} -gc RED BLUE
  \\x1b[41;34m

  Print the string with the escape sequence:
    {basename(__file__)} -cg RED BLUE \"HELLO WORLD\"
  \\x1b[31;44mHELLO WORLD\\x1b[m

  Print the escaped string with colors:
    {basename(__file__)} --escape -cg RED BLUE \"HELLO WORLD\"
  HELLO WORLD

  Print the escaped string with words of different colors:
    {basename(__file__)} -ecg RED BLUE HELLO -r ' ' -cg CYAN MAGENTA WORLD
  HELLO WORLD

  Print the escaped string with colors:
    {basename(__file__)} -ecg RED BLUE --this-is-not-an-option
  --this-is-not-an-option

  If you want to give a string that is equal to an option, it must be
  enclosed in quotation marks (for the shell) and start with a backslash
  (for the program). Single quotes are preferred than double quotes.
  Print the escaped string \"-E\" with colors:
    {basename(__file__)} -ecg RED BLUE '\\-E'
  -E

  In fact, any string starting with backslash will strip the backslash:
    {basename(__file__)} -ecg RED BLUE '\\HELLO WORLD'
  HELLO WORLD
    {basename(__file__)} -ecg RED BLUE '\\\\HELLO WORLD'
  \\HELLO WORLD

  Print the escaped string with hexadecimal colors:
    {basename(__file__)} -ecg cc0000 \\#2986cc \"HELLO WORLD\"
    {basename(__file__)} -ecg '#cc0000' \"#2986cc\" \"HELLO WORLD\"
  HELLO WORLD

  Print the escaped string with RGB colors:
    {basename(__file__)} -ecg 255,0,0 1,99,255 \"HELLO WORLD\"
  HELLO WORLD

Exit status: 
  Returns 1 if an invalid color is given.
  Returns 0 otherwise.

This program is licensed under GPL-3.0-or-later.
""", end="")
	exit(0)

def print_about() -> None:
	print("""\
escolor 1.0.0
Copyright © 2024 Jesús Arenas
Official repository: https://github.com/podobu/escolor
License GPLv3+: GNU GPL version 3 or later <https://gnu.org/licenses/gpl.html>.
""", end="")
	exit(0)

def parse_options(argv: list, awv: str = "") -> list:
	parsed_args: list = []
	arg: str
	swv: str = "" # shorts with values
	lwv: list = [] # longs with values
	i: int = 0

	while i < len(awv) and awv[i] != ':':
		swv += awv[i]
		i += 1
	if i + 1 < len(awv):
		lwv = awv[i+1:].split(sep=':')

	i = 0

	while i < len(argv):
		arg = argv[i]

		if arg[0:1] == '-' and len(arg) > 1:
			if arg[1:2] == '-' and len(arg) > 2:
				parsed_args.append(arg)
				if arg[2:] in lwv:
					i += 1
					if i < len(argv):
						parsed_args.append(argv[i])
					else:
						parsed_args.append("")
			else:
				for option in arg[1:]:
					parsed_args.append("-" + option)
					if option in swv:
						i += 1
						if i < len(argv):
							parsed_args.append(argv[i])
						else:
							parsed_args.append("")
		else:
			parsed_args.append(arg)

		i += 1

	return parsed_args

def throw_color_error(color: str = "") -> None:
	if color:
		color = "'" + color + "'"
	else:
		color = "NO COLOR GIVEN"
	print(f"{basename(__file__)}: Invalid color given: {color}. See usage with -h or --help.",
		file=stderr)
	exit(1)

def get_color(color: str, background: int = 0) -> str:
	color = color.upper()
	if background: background = 10
	match color:
		case 'BLACK': color = f"{background+30}"
		case 'RED': color = f"{background+31}"
		case 'GREEN': color = f"{background+32}"
		case 'YELLOW': color = f"{background+33}"
		case 'BLUE': color = f"{background+34}"
		case 'MAGENTA': color = f"{background+35}"
		case 'CYAN': color = f"{background+36}"
		case 'WHITE': color = f"{background+37}"
		case 'BBLACK': color = f"{background+90}"
		case 'BRED': color = f"{background+91}"
		case 'BGREEN': color = f"{background+92}"
		case 'BYELLOW': color = f"{background+93}"
		case 'BBLUE': color = f"{background+94}"
		case 'BMAGENTA': color = f"{background+95}"
		case 'BCYAN': color = f"{background+96}"
		case 'BWHITE': color = f"{background+97}"
		case _:
			# 8 bit color
			if search(r"^\d{1,3}$", color) and int(color) < 256:
				color = f"{background+38};5;{color}"
			# hex color
			elif search(r"^#?[\dA-F]{6}$", color):
				color = color.lstrip("#")
				r, g, b = (int(color[i:i+1], 16) * 16 + int(color[i+1:i+2], 16) for i in range(0, 5, 2))
				color = f"{background+38};2;{r};{g};{b}"
			# rgb color
			elif search(r"^\d{1,3},\d{1,3},\d{1,3}$", color):
				r, g, b = (int(x) for x in color.split(','))
				if r < 256 and g < 256 and b < 256:
					color = f"{background+38};2;{r};{g};{b}"
				else:
					return ""
			else:
					return ""
	return color

# Returning
output_string: str = "\x1b["
# Option logic
parsed_args: list = parse_options(argv[1:], "cg")
i: int = 0
color: str
# Flags
escape: bool = False
newline: chr = '\n'

while i < len(parsed_args):

	match parsed_args[i]:
		case '-h' | "--help": print_usage()
		case '-v' | "--version": print_about()

		case '-e' | "--escape": escape = True
		case '-n' | "--newline": newline = '\n'
		case '-E' | "--no-escape": escape = False
		case '-N' | "--no-newline": newline = ''

		case '-c' | "--color":
			if i < len(parsed_args) - 1:
				color = get_color(parsed_args[i+1])
				if not color:
					throw_color_error(parsed_args[i+1])
				else:
					output_string += color + ";"
					i += 1
			else:
				throw_color_error()
		case '-g' | "--background":
			if i < len(parsed_args) - 1:
				color = get_color(parsed_args[i+1], 1)
				if not color:
					throw_color_error(parsed_args[i+1])
				else:
					output_string += color + ";"
					i += 1
			else:
				throw_color_error()
		case '-b' | "--bold": output_string += "1;"
		case '-i' | "--italic": output_string += "3;"
		case '-u' | "--underline": output_string += "4;"
		case '-d' | "--double-underline": output_string += "21;"
		case '-o' | "--overline": output_string += "53;"
		case '-t' | "--crossed-out": output_string += "9;"
		case '-k' | "--blink": output_string += "5;"
		case '-s' | "--swap": output_string += "7;"

		case '-C' | "--no-color": output_string += "39;"
		case '-G' | "--no-background": output_string += "49;"
		case '-B' | "--no-bold": output_string += "22;"
		case '-I' | "--no-italic": output_string += "23;"
		case '-U' | "--no-underline": output_string += "24;"
		case '-O' | "--no-overline": output_string += "55;"
		case '-T' | "--no-crossed-out": output_string += "29;"
		case '-K' | "--no-blink": output_string += "25;"
		case '-S' | "--no-swap": output_string += "27;"
		case '-r' | "--reset": output_string += "0;"
		case _:
			# output_string always ends in ";" or "\x1b["
			if output_string[-1] == ";":
				output_string = output_string.rstrip(";")
				output_string += "m"
			else:
				output_string = output_string.rstrip("\x1b[")
			parsed_args[i] = parsed_args[i].removeprefix("\\")
			output_string += f"{parsed_args[i]}\x1b["

	i += 1

if escape:
	print(f"{output_string.rstrip(';')}m", end=newline)
else:
	output_string = repr(f"{output_string.rstrip(';')}m")
	match output_string[0]:
		case "'":
			output_string = output_string.strip("'")
		case '"':
			output_string = output_string.strip('"')
	print(output_string, end=newline)
