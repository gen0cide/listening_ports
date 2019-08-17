#!/usr/local/bin/bash
# --------------------------------------------------------------------------------------------------
#
#	listening_ports.bash
#
# Utility to display what processes are listening on what ports.
#
# @author:    Alex Levinson
# @email:     gen0cide.threats@gmail.com
# @source:    github.com/gen0cide/listening_ports
# @twitter:   twitter.com/alexlevinson
# @copyright: Copyright 2019 Alex Levinson
# @license:   GPLv3 (https://github.com/gen0cide/listening_ports/blob/master/LICENSE)
# @version:   1.0.0
#
# --------------------------------------------------------------------------------------------------
#
# Declare variables for the configuration of the tool.
#
LISTENING_PORTS_VERSION="1.0.0"
LISTENING_PORTS_PROGNAME="listening_ports"
LISTENING_PORTS_TITLE="macOS utility to show what processes are listening on which ports."
LISTENING_PORTS_DESCRIPTION="The intent of this program is to perform the same function typically accomplished by the command 'netstat -natp'. This command is not possible on macOS operating systems (specifically the '-p' part), so this utility uses 'lsof' and to get and print the same information, with some fancy terminal coloring and filtering features."
LISTENING_PORTS_AUTHOR="Alex Levinson <alexl@uber.com>"
LISTENING_PORTS_WEBSITE="https://github.com/gen0cide/listening_ports"
LISTENING_PORTS_COPYRIGHT="(c) Copyright 2019 Alex Levinson"
GRC_CONFIG_NAME="${GRC_CONFIG_NAME:-conf.listening_ports}"
OPT_PARSE_LIBRARY_PATH="${OPT_PARSE_LIBRARY_PATH:-/usr/local/lib/optparse.bash}"
LSOF_SOCKET_TYPE="tcp"
NAMED_USER=""
NAMED_PID=""
PROC_NAME=""
NAMED_PORT=""
FILTER_LOCAL="off"
IP_STACK_VERSION="both"
# --------------------------------------------------------------------------------------------------
#
#	Helper function to automatically fail with some error text upon certain conditions.
#

die() {
	local _ret=$2
	test -n "$_ret" || _ret=1
	test "$_PRINT_HELP" = yes && print_help >&2
	echo "$1" >&2
	exit ${_ret}
}

# --------------------------------------------------------------------------------------------------
#
#	Helper function to test if an argument is simply a short option to parse.
#

begins_with_short_option() {
	local first_option all_short_options='oudapivh'
	first_option="${1:0:1}"
	test "$all_short_options" = "${all_short_options/$first_option/}" && return 1 || return 0
}

# --------------------------------------------------------------------------------------------------
#
#	Print the help menu.
#

print_help() {
	printf 'NAME:\n'
	printf '  %s - %s\n\n' $LISTENING_PORTS_PROGNAME "$LISTENING_PORTS_TITLE"
	printf 'USAGE:\n'
	printf '  %s [OPTIONS]\n\n' $LISTENING_PORTS_PROGNAME
	printf 'VERSION:\n'
	printf '  %s\n\n' $LISTENING_PORTS_VERSION
	printf 'DESCRIPTION:\n'
	printf '  %s\n\n' "$LISTENING_PORTS_DESCRIPTION"
	printf 'AUTHOR:\n'
	printf '  %s\n\n' "$LISTENING_PORTS_AUTHOR"
	printf 'WEBSITE:\n'
	printf '  %s\n\n' "$LISTENING_PORTS_WEBSITE"
	printf 'OPTIONS:\n'
	printf '  %s\n' "-o, --protocol         What type of sockets to display. Acceptable values: tcp, udp, all. (default: 'tcp')"
	printf '  %s\n' "-u, --user             Filter the results for a specific user. This can be a regular expression."
	printf '  %s\n' "-d, --process-id       Only show results for a specified process ID."
	printf '  %s\n' "-a, --process-name     Only show results for a processes that match the provided term. This can be a regular expression."
	printf '  %s\n' "-p, --port             Filter the results for a specific port number."
	printf '  %s\n' "-i, --ip-version       Only include results for a ports bound to a specific IP version. Acceptable values: ipv4, ipv6, both. (default: 'both')"
	printf '  %s\n' "    --hide-local       Do not display ports that are only bound to local interfaces."
	printf '  %s\n' "-v, --version          Prints version information."
	printf '  %s\n' "-h, --help             Prints the help menu."
	printf '\n'
	printf 'COPYRIGHT:\n'
	printf '  %s\n' "$LISTENING_PORTS_COPYRIGHT"
}

# --------------------------------------------------------------------------------------------------
#
#	Parse command line arguments.
#

parse_commandline() {
	while test $# -gt 0; do
		_key="$1"
		case "$_key" in
		-o | --protocol)
			test $# -lt 2 && die "Missing value for the optional argument '$_key'." 1
			LSOF_SOCKET_TYPE="$2"
			shift
			;;
		--protocol=*)
			LSOF_SOCKET_TYPE="${_key##--protocol=}"
			;;
		-o*)
			LSOF_SOCKET_TYPE="${_key##-o}"
			;;
		-u | --user)
			test $# -lt 2 && die "Missing value for the optional argument '$_key'." 1
			NAMED_USER="$2"
			shift
			;;
		--user=*)
			NAMED_USER="${_key##--user=}"
			;;
		-u*)
			NAMED_USER="${_key##-u}"
			;;
		-d | --process-id)
			test $# -lt 2 && die "Missing value for the optional argument '$_key'." 1
			NAMED_PID="$2"
			shift
			;;
		--process-id=*)
			NAMED_PID="${_key##--process-id=}"
			;;
		-d*)
			NAMED_PID="${_key##-d}"
			;;
		-a | --process-name)
			test $# -lt 2 && die "Missing value for the optional argument '$_key'." 1
			PROC_NAME="$2"
			shift
			;;
		--process-name=*)
			PROC_NAME="${_key##--process-name=}"
			;;
		-a*)
			PROC_NAME="${_key##-a}"
			;;
		-p | --port)
			test $# -lt 2 && die "Missing value for the optional argument '$_key'." 1
			NAMED_PORT="$2"
			shift
			;;
		--port=*)
			NAMED_PORT="${_key##--port=}"
			;;
		-p*)
			NAMED_PORT="${_key##-p}"
			;;
		--no-hide-local | --hide-local)
			FILTER_LOCAL="on"
			test "${1:0:5}" = "--no-" && FILTER_LOCAL="off"
			;;
		-i | --ip-version)
			test $# -lt 2 && die "Missing value for the optional argument '$_key'." 1
			IP_STACK_VERSION="$2"
			shift
			;;
		--ip-version=*)
			IP_STACK_VERSION="${_key##--ip-version=}"
			;;
		-i*)
			IP_STACK_VERSION="${_key##-i}"
			;;
		-v | --version)
			echo "$LISTENING_PORTS_VERSION"
			exit 0
			;;
		-v*)
			echo "$LISTENING_PORTS_VERSION"
			exit 0
			;;
		-h | --help)
			print_help
			exit 0
			;;
		-h*)
			print_help
			exit 0
			;;
		*)
			_PRINT_HELP=yes die "FATAL ERROR: Got an unexpected argument '$1'" 1
			;;
		esac
		shift
	done
}

parse_commandline "$@"
# --------------------------------------------------------------------------------------------------
#
# Check for required dependencies.
#

function check_sed_version() {
	local currentver
	if ! currentver="$(sed --version | head -n 1 | cut -f4 -d' ')"; then
		_PRINT_HELP=no die "[!] FATAL ERROR: sed --version failed. Is GNU sed installed and in the path?" "" 1
	fi
	requiredver="4.7"
	if [ "$(printf '%s\n' "$requiredver" "$currentver" | sort -V | head -n1)" = "$requiredver" ]; then
		return
	else
		_PRINT_HELP=no die "[!] FATAL ERROR: Incompatible version of sed detected. DETECTED=${currentver} REQUIRES>=${requiredver}" "" 1
	fi
}

function check_bash_version() {
	local currentver
	if ! currentver="$(bash --version | head -n 1 | awk '{print $4}')"; then
		_PRINT_HELP=no die "[!] FATAL ERROR: bash --version failed. Is GNU bash installed and in the path?" "" 1
	fi
	requiredver="5.0.0"
	if [ "$(printf '%s\n' "$requiredver" "$currentver" | sort -V | head -n1)" = "$requiredver" ]; then
		return
	else
		_PRINT_HELP=no die "[!] FATAL ERROR: Incompatible version of bash detected. DETECTED=${currentver} REQUIRES>=${requiredver}" "" 1
	fi
}

function check_gawk_version() {
	local currentver
	if ! currentver="$(gawk --version | head -n 1 | awk '{gsub(/,/, "", $3); print $3}')"; then
		_PRINT_HELP=no die "[!] FATAL ERROR: gawk --version failed. Is GNU awk (gawk) installed and in the path?" "" 1
	fi
	requiredver="5.0"
	if [ "$(printf '%s\n' "$requiredver" "$currentver" | sort -V | head -n1)" = "$requiredver" ]; then
		return
	else
		_PRINT_HELP=no die "[!] FATAL ERROR: Incompatible version of gawk detected. DETECTED=${currentver} REQUIRES>=${requiredver}" "" 1
	fi
}

function check_grc_version() {
	local currentver
	if ! currentver="$(grc --version | head -n 1 | awk '{print $3}')"; then
		_PRINT_HELP=no die "[!] FATAL ERROR: sed --version failed. Is GNU sed installed and in the path?" "" 1
	fi
	requiredver="1.11"
	if [ "$(printf '%s\n' "$requiredver" "$currentver" | sort -V | head -n1)" = "$requiredver" ]; then
		return
	else
		_PRINT_HELP=no die "[!] FATAL ERROR: Incompatible version of sed detected. DETECTED=${currentver} REQUIRES>=${requiredver}" "" 1
	fi

	local test_grc
	test_grc="$(grc -c "${GRC_CONFIG_NAME}" whoami)"
	if [ "$test_grc" == "config file ${GRC_CONFIG_NAME} not found" ]; then
		_PRINT_HELP=no die "[!] FATAL ERROR: The GRC config ${GRC_CONFIG_NAME} was not in the grc's config path. Check ~/.grc/, /usr/share/grc/, /usr/local/share/grc, or (brew --prefix grc)/share/grc directories for it's existence." "" 1
	fi
}

check_sed_version
check_bash_version
check_gawk_version
check_grc_version
# --------------------------------------------------------------------------------------------------
#
# Perform initial configuration of lsof and it's command options.
#

LSOF_INCLUDE_TCP="${LSOF_INCLUDE_TCP:--iTCP -sTCP:LISTEN}"
LSOF_INCLUDE_UDP="${LSOF_INCLUDE_UDP:--iUDP}"
case "$LSOF_SOCKET_TYPE" in
tcp)
	LSOF_INCLUDES="${LSOF_INCLUDE_TCP}"
	;;
udp)
	LSOF_INCLUDES="${LSOF_INCLUDE_UDP}"
	;;
all)
	LSOF_INCLUDES="${LSOF_INCLUDE_TCP} ${LSOF_INCLUDE_UDP}"
	;;
*)
	echo "[!] Invalid value for --type/-t. Must be one of the following: tcp, udp, all."
	exit 1
	;;
esac
LSOF_ARGS="${LSOF_INCLUDES} -n -P +c 0 -R -V"
# --------------------------------------------------------------------------------------------------
#
# DEFINE GAWK SCRIPTS
#

# GAWK_FORMATTER is the initial script that conforms the output to a TSV format, including headers.
read -r -d '' GAWK_FORMATTER <<'EOM'
BEGIN {
	print "PROCESS", "\t", "PID", "\t", "PPID", "\t", "USER", "\t", "PROTOCOL", "\t", "SOCKET", "\t"
}
{
	if ((NR > 1) && ($10 != "*:*")) print $1, "\t", $2, "\t", $3, "\t", $4, "\t", $9, "\t", $10
}
EOM

# Filters results with a user provided regular expression.
read -r -d '' USER_FILTER_SCRIPT <<'EOM'
{
	if (NR == 1) print $0
}
{
	if (NR > 1 && $4 ~ named_user) print $0
}
EOM

# Filter results that don't match the provided process ID.
read -r -d '' PID_FILTER_SCRIPT <<'EOM'
{
	if (NR == 1) print $0
}
{
	if (NR > 1 && $2 == named_pid) print $0
}
EOM

# Filter results that don't match the provided regular expression against process name.
read -r -d '' PROC_NAME_FILTER_SCRIPT <<'EOM'
{
	if (NR == 1) print $0
}
{
	IGNORECASE = 1
	if (NR > 1 && $1 ~ named_proc) print $0
}
EOM

# Filter the results that don't match the provided port number.
read -r -d '' PORT_NUMBER_FILTER_SCRIPT <<'EOM'
{
	if (NR == 1) print $0
}
{
	match($6, /^.*:([0-9]+)$/, socket)
	if (NR > 1 && named_port == socket[1]) print $0
}
EOM

# Remove results that are bound to localhost (ipv4 and ipv6)
read -r -d '' NO_LOCAL_FILTER_SCRIPT <<'EOM'
{
	if (NR == 1) print $0
}
{
	match($6, /^(.*):([0-9]+)$/, socket)
	if( (NR >=2) &&
			(socket[1] == "*") &&
				( (socket[1] !~ /127\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}/) ||
					(socket[1] !~ /\[fe80.*\]/) ||
					(socket[1] !~ /\[::1\]/))) print $0
}
EOM

# Remove results that are bound to an IPv4 stack.
read -r -d '' FILTER_IPV4_SCRIPT <<'EOM'
{
	if (NR == 1) print $0
}
{
	match($6, /^(.*):([0-9]+)$/, socket)
	if( (NR >=2) &&
			((socket[1] == "*") ||
			(socket[1] ~ /[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}/))) print $0
}
EOM

# Remove results that are bound to an IPv6 stack.
read -r -d '' FILTER_IPV6_SCRIPT <<'EOM'
{
	if (NR == 1) print $0
}
{
	match($6, /^(.*):([0-9]+)$/, socket)
	if( (NR >=2) &&
			((socket[1] == "*") || (socket[1] ~ /\[.*\]/))) print $0
}
EOM
# --------------------------------------------------------------------------------------------------
#
# Perform initial lsof command and strip out non-socket ports returned.
#

# shellcheck disable=SC2086 disable=SC2090
base_results="$(lsof ${LSOF_ARGS})"
# --------------------------------------------------------------------------------------------------
#
# Normalize initial command results into a TSV format.
#

structured_results="$(
	echo "$base_results" |
		gawk "${GAWK_FORMATTER}" |
		sed 's/\\x20/ /g;' |
		column -t -s $'\t'
)"
# --------------------------------------------------------------------------------------------------
#
# Filter results based on named paramters provided to the application.
#

# Filter by username
if [ "$NAMED_USER" != "" ]; then
	structured_results="$(
		echo "$structured_results" |
			gawk -v named_user="$NAMED_USER" "${USER_FILTER_SCRIPT}"
	)"
fi

# Filter by process ID
if [ "$NAMED_PID" != "" ]; then
	structured_results="$(
		echo "$structured_results" |
			gawk -v named_pid="$NAMED_PID" "${PID_FILTER_SCRIPT}"
	)"
fi

# Filter by process name
if [ "$PROC_NAME" != "" ]; then
	structured_results="$(
		echo "$structured_results" |
			gawk -v named_proc="$PROC_NAME" "${PROC_NAME_FILTER_SCRIPT}"
	)"
fi

# Filter by named port
if [ "$NAMED_PORT" != "" ]; then
	structured_results="$(
		echo "$structured_results" |
			gawk -v named_port="$NAMED_PORT" "${PORT_NUMBER_FILTER_SCRIPT}"
	)"
fi

# Remove local listeners if specified
if [ "$FILTER_LOCAL" != "" ] && [ "$FILTER_LOCAL" == "on" ]; then
	structured_results="$(
		echo "$structured_results" |
			gawk "${NO_LOCAL_FILTER_SCRIPT}"
	)"
fi

# Filter based on IP stack.
case "$IP_STACK_VERSION" in
ipv4)
	structured_results="$(
		echo "$structured_results" |
			gawk "${FILTER_IPV4_SCRIPT}"
	)"
	;;
ipv6)
	structured_results="$(
		echo "$structured_results" |
			gawk "${FILTER_IPV6_SCRIPT}"
	)"
	;;
both)
	# continue as intended.
	;;
*)
	echo "[!] Invalid value for --ip-version/-i. Must be one of the following: ipv4, ipv6, both."
	exit 1
	;;
esac
# --------------------------------------------------------------------------------------------------
#
# Pretty print the results
#

echo "$structured_results" | grcat "${GRC_CONFIG_NAME}"
# --------------------------------------------------------------------------------------------------
