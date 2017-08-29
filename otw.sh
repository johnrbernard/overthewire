#!/bin/bash

# otw - Play OverTheWire wargames
# Copyright (C) 2017  John R Bernard  <john3bernard@gmail.com>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#


program_name="$(basename "$0")"
otw_baseurl="overthewire.org"

# Default option values (use options to deviate from defaults)
# -g
use_git="false"
# -p
use_port="false"
# -s
force_ssh="false"
# -t
use_gui="true"
# -u
use_url="false"

# Default ports corresponding to each game
BANDIT_PORT=2220
BEHEMOTH_PORT=2221
KRYPTON_PORT=2222
LEVIATHAN_PORT=2223
MANPAGE_PORT=2224
MAZE_PORT=2225
NARNIA_PORT=2226
UTUMNO_PORT=2227
VORTEX_PORT=2228
SEMTEX_PORT=2229
DRIFTER_PORT=2230

usage ()
{
    cat <<EOF
Usage: $program_name [-ghstu] [-p=<ssh_port> | -p <ssh_port>] <game> [<level>]

This program reads a password from ./<game>/<level> and will exit if ./<game>
does not exist as a directory.

If <level> is not provided, the highest number file within ./<game> will be
used; if such a file does not exist, then 0 will be used.

If -p is specified, then <ssh_port> will be the port used to connect to <game>
regardless of the contents of <game>/port (implies -s).  Else, the contents of
<game>/port will be used as the port, or if that file does not exist then the
program will try to determine which port to use based on <game>.

Options
    -h, --help: Show this help message.
    --: Don't interpret the rest of the arguments as options.
    -g, --git: Use git to commit each password addition. Requires git
        installation.
    -p, --port: Use <ssh_port> to connect to the game using ssh. Implies -s.
    -s, --ssh: Override any game-specific command and instead use ssh.
    -t, --terminal: Don't use commands related to GUI (e.g. xdg-open).  If you
        don't use this option, then you must have installed packages 'xdg-open'
        and 'xclip'.  This option will be automatically added if the user has
        not installed both 'xdg-open' and 'xclip'.
    -u, --url: Print or xdg-open
        overthewire.org/wargames/<game>/<game><level>.html every time a level
        is played if there is information on that page.
        Note: in levels that are played in browser rather than in a terminal
        (e.g. natas), this option does not effect whether the level URL (e.g.
        http://natasX.natas.labs.overthewire.org) is opened in-browser or
        printed.
EOF
}

RED='\033[0;31m'
GREEN='\033[0;32m'
L_CYAN='\033[1;36m'
NC='\033[0m'

# Used to differentiate between output from this program and output from OTW.
# https://stackoverflow.com/questions/5947742/how-to-change-the-output-color-of-echo-in-linux#answer-5947802
echo_color ()
{
    printf "${GREEN}$@${NC}\n"
}

echo_error ()
{
    printf "${RED}$@${NC}\n"
}

# Visually indicate that the text printed is intended to be copied-and-pasted.
echo_copy ()
{
    printf "${L_CYAN}$@${NC}\n"
}

# https://stackoverflow.com/questions/592620/check-if-a-program-exists-from-a-bash-script#answer-677212
check_gui_cmds ()
{
    command -v xclip >/dev/null 2>&1 || return 1
    command -v xdg-open >/dev/null 2>&1 || return 1

    return 0
}

# From $1 (game), print the game's ssh port to stdout or return 1.
game_port ()
{
    local game="$1"

    case "$game" in
    bandit)
        echo "$BANDIT_PORT"
        ;;
    behemoth)
        echo "$BEHEMOTH_PORT"
        ;;
    krypton)
        echo "$KRYPTON_PORT"
        ;;
    leviathan)
        echo "$LEVIATHAN_PORT"
        ;;
    manpage)
        echo "$MANPAGE_PORT"
        ;;
    maze)
        echo "$MAZE_PORT"
        ;;
    narnia)
        echo "$NARNIA_PORT"
        ;;
    utumno)
        echo "$UTUMNO_PORT"
        ;;
    vortex)
        echo "$VORTEX_PORT"
        ;;
    semtex)
        echo "$SEMTEX_PORT"
        ;;
    drifter)
        echo "$DRIFTER_PORT"
        ;;
    *)
        return 1
        ;;
    esac

    return 0
}

save_password ()
{
    local game="$1"
    local level="$2"
    local password="$3"

    echo "$password" >$game/$level
    if [ "x$use_git" == "xtrue" ]; then
        [ -d .git ] || git init
        if [ $? -eq 0 ]; then
            git add "$game/$level"
            git commit -m "$game$level"
        fi
    fi
}

load_password_noprompt ()
{
    local game="$1"
    local level="$2"

    cat "$game/$level" 2>/dev/null
    return 0
}

load_password ()
{
    local game="$1"
    local level="$2"

    local password="$(cat "$game/$level" 2>/dev/null)"
    while [ ! -n "$password" ]; do
        printf "${GREEN}Enter password for $game$level:${NC}" >&2
        read password || return 1
    done

    echo "$password"

    return 0
}

game_ssh ()
{
    local game="$1"
    local level="$2"
    local password="$3"

    local port
    local re

    # The reason why the user is allowed to override the port used is for
    # forwards compatability, for instance if the port number of any level
    # changes or if a new level is added.
    if [ "x$use_port" == "xtrue" ]; then
        port="$option_port"
    elif [ -f "$game/port" ]; then
        port="$(cat "$game/port")"
        re='^[1-9][0-9]*$'
        if ! [[ $port =~ $re ]]; then
            port="$(game_port "$game")"
            if [ $? -ne 0 ]; then
                echo_error "Error: program doesn't know port for '$game'" >&2
                echo_error "Try running the program with the option -p (run $program_name --help for more information)." >&2
                return 1
            fi
        fi
    else
        port="$(game_port "$game")"
        if [ $? -ne 0 ]; then
            echo_error "Error: program doesn't know port for '$game'" >&2
            echo_error "Try running the program with the option -p (run $program_name --help for more information)." >&2
            return 1
        fi
    fi

    # There's no reason to show the user the server's key since overthewire.org
    # doesn't even provide a key on their website (as far as I know).
    sshpass -p "$password" ssh -oStrictHostKeyChecking=no -p "$port" $game$level@$game.labs.$otw_baseurl

    return 0
}

game_specific_command ()
{
    local game="$1"
    local level="$2"

    local password
    local ret

    case "$game" in
    bandit)
        echo_color "$game$level"
        if [ "x$use_url" == "xtrue" ]; then
            if [ "x$use_gui" == "xtrue" ]; then
                nohup xdg-open "http://$otw_baseurl/wargames/$game/$game$current_level.html" >/dev/null 2>&1 &
            else
                echo_copy "http://$otw_baseurl/wargames/$game/$game$current_level.html"
            fi
        fi

        # bandit level 0 players may not know how to use ssh
        if [ "x$level" == "x0" ]; then
            echo_color "It's important that you know how to use the ssh command."
            echo_color "If you don't know how to ssh to $game.labs.$otw_baseurl port $BANDIT_PORT,"
            echo_color "then learn and attempt to do so by typing 'man ssh'."
            echo
            echo_color "Continue (ignore this message) by pressing <ENTER>,"
            echo_color "or quit this program by pressing ^D."
            read || return 3
        fi

        password="$(load_password "$game" "$level")"
        [ $? -eq 0 ] || return 1

        game_ssh "$game" "$level" "$password"

        ret=$?
        ;;
    # Only ssh to the level, and there is no information at
    # overthewire.org/wargames/$game/$game$level.html
    # (all of these are from intruded.net in August 2017)
    behemoth | leviathan | manpage | maze | narnia | utumno)
        echo_color "$game$level"

        password="$(load_password "$game" "$level")"
        [ $? -eq 0 ] || return 1

        game_ssh "$game" "$level" "$password"

        ret=$?
        ;;
    # Level 0 is the only level that isn't completed through ssh, and
    # there is information at overthewire.org/wargames/$game/$game$level.html
    krypton | vortex | semtex)
        echo_color "$game$level"

        case "$level" in
        0)
            if [ "x$use_gui" == "xtrue" ]; then
                nohup xdg-open "http://$otw_baseurl/wargames/$game/$game$level.html" &
            else
                echo_copy "http://$otw_baseurl/wargames/$game/$game$level.html"
            fi

            ret=0
            ;;
        *)
            password="$(load_password "$game" "$level")"
            [ $? -eq 0 ] || return 1

            game_ssh "$game" "$level" "$password"

            ret=$?
            ;;
        esac
        ;;
    # Accessed through an internet browser instead of ssh
    natas)
        echo_color "$game$level"

        password="$(load_password_noprompt "$game" "$level")"

        if [ "x$use_gui" == "xtrue" ]; then
            echo "$password" | xclip -selection clipboard &&
                echo_color "Password to $game$level copied to clipboard" ||
                echo_copy "$password"
        else
            echo_copy "$password"
        fi

        if [ "x$use_gui" == "xtrue" ]; then
            nohup xdg-open "http://$game$level.$game.labs.$otw_baseurl" &
        else
            echo_copy "http://$game$level.$game.labs.$otw_baseurl"
        fi

        ret=0
        ;;
    *)
        echo_error "'$game' is not implemented in this program. Use the -s option to override this" >&2
        echo_error "warning and use ssh." >&2
        return 2
        ;;
    esac

    return $ret
}

main ()
{
    local game="$1"
    local level="$2"

    local next_level
    local password

    while true; do
        next_level=$((level+1))

        if [ "x$force_ssh" == "xtrue" ]; then
            echo_color "$game$level"

            password="$(load_password "$game" "$level")"
            [ $? -eq 0 ] || exit 0

            game_ssh "$game" "$level" "$password" ||
                exit 0
        else
            game_specific_command "$game" "$level" ||
                exit 0
        fi

        echo_color "Save password (type password + <ENTER>), exit (^D), or retry level (<ENTER>)"
        read password || exit 0
        [ "x$password" == "x" ] && continue

        save_password "$game" "$next_level" "$password"

        echo_color "<ENTER> for next level or ^D to quit"
        read || return
        level=$next_level
    done
}

while true; do
    case "$1" in
    -h | --help)
        usage
        exit 0
        ;;
    -g | --git)
        use_git="true"
        shift
        ;;
    -p | --port)
        if [ $# -eq 1 ]; then
            echo_error "$program_name: must specify an argument to option '$1'" >&2
            exit 2
        fi

        option_port="$2"
        use_port="true"
        force_ssh="true"
        shift 2
        ;;
    -p=* | --port=*)
        option_port="$(echo "$1" | cut -d'=' -f2)"

        use_port="true"
        force_ssh="true"
        shift
        ;;
    -s | --ssh)
        force_ssh="true"
        shift
        ;;
    -t | --terminal)
        use_gui="false"
        shift
        ;;
    -u | --url)
        use_url="true"
        shift
        ;;
    --)
        shift
        break
        ;;
    -*)
        echo_error "$program_name: unknown option '$1'" >&2
        echo_error "Try '$program_name --help' for more information." >&2
        exit 2
        ;;
    *)
        break
        ;;
    esac
done

if [ $# -eq 2 ]; then
    game="$1"
    if [ ! -d "$game" ]; then
        # A user might accidentally run this program in the wrong directory,
        # so let them know that they might have made a mistake.
        echo_error "$program_name: $game: no such directory" >&2
        exit 2
    fi
    level="$2"
elif [ $# -eq 1 ]; then
    game="$1"
    if [ ! -d "$game" ]; then
        echo_error "$program_name: $game: no such directory" >&2
        exit 2
    fi
    re='(^[1-9][0-9]*$)|(^0$)'
    level="$(ls "$game" | sort -n | grep -E $re | tail -1)"
    if [ ! -n "$level" ]; then
        level=0
    fi
else
    usage
    exit 2
fi

if [ "x$use_gui" == "xtrue" ]; then
    if ! check_gui_cmds; then
        echo_color "$program_name: Using -t option" >&2
        use_gui="false"
    fi
fi

main "$game" "$level"

# vim: et ts=4 sw=4
