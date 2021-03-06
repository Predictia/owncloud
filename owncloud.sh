#!/usr/bin/env bash
#===============================================================================
#          FILE: owncloud.sh
#
#         USAGE: ./owncloud.sh
#
#   DESCRIPTION: Entrypoint for owncloud docker container
#
#       OPTIONS: ---
#  REQUIREMENTS: ---
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: David Personette (dperson@gmail.com),
#  ORGANIZATION:
#       CREATED: 09/28/2014 12:11
#      REVISION: 1.0
#===============================================================================

set -o nounset                              # Treat unset variables as an error

### timezone: Set the timezone for the container
# Arguments:
#   timezone) for example EST5EDT
# Return: the correct zoneinfo file will be symlinked into place
timezone() { local timezone="${1:-EST5EDT}"
    [[ -e /usr/share/zoneinfo/$timezone ]] || {
        echo "ERROR: invalid timezone specified" >&2
        return
    }

    ln -sf /usr/share/zoneinfo/$timezone /etc/localtime
}

### usage: Help
# Arguments:
#   none)
# Return: Help text
usage() { local RC=${1:-0}
    echo "Usage: ${0##*/} [-opt] [command]
Options (fields in '[]' are optional, '<>' are required):
    -h          This help
    -t \"\"       Configure timezone
                possible arg: \"[timezone]\" - zoneinfo timezone for container

The 'command' (if provided and valid) will be run instead of ownCloud
" >&2
    exit $RC
}

while getopts ":ht:" opt; do
    case "$opt" in
        h) usage ;;
        t) timezone "$OPTARG" ;;
        "?") echo "Unknown option: -$OPTARG"; usage 1 ;;
        ":") echo "No argument value for option: -$OPTARG"; usage 2 ;;
    esac
done
shift $(( OPTIND - 1 ))

[[ "${TIMEZONE:-""}" ]] && timezone "$TIMEZONE"

mkdir -p /var/run/lighttpd
find /var/www/owncloud -type f -print0 | xargs -0 chmod 0640
find /var/www/owncloud -type d -print0 | xargs -0 chmod 0750
chown -Rh root:www-data /var/www/owncloud
chown -Rh www-data. /var/run/lighttpd /var/www/owncloud/apps \
            /var/www/owncloud/config /var/www/owncloud/data
chown root:www-data /var/www/owncloud/data/.htaccess 2>/dev/null
chmod 0644 /var/www/owncloud/.htaccess /var/www/owncloud/data/.htaccess \
            2>/dev/null

if [[ $# -ge 1 && -x $(which $1 2>&-) ]]; then
    exec "$@"
elif [[ $# -ge 1 ]]; then
    echo "ERROR: command not found: $1"
    exit 13
else
    exec lighttpd -D -f /etc/lighttpd/lighttpd.conf
fi
