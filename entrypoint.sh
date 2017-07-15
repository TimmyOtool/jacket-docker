#!/bin/bash -x


# Set the uid:gid to run as
[ "$jackett_uid" ] && usermod  -o -u "$jackett_uid" jackett
[ "$jackett_gid" ] && groupmod -o -g "$jackett_gid" jackett


# Set folder permissions
chown -R jackett:jackett /jackett /config


# Disable the logfile on disk (because we have docker logs instead)
_jackett_logfile="/config/.config/Jackett/log.txt"
mkdir -p "$(dirname "$_jackett_logfile")"
ln -sf /dev/null $_jackett_logfile


# Copy "$@" special variable into a regular variable
_jackett_args="$@"


# Start the jackett daemon. web UI should bind to *:9117 with default args
sudo -E su "jackett" << EOF
	set -x
	mono /jackett/JackettConsole.exe $_jackett_args
EOF

