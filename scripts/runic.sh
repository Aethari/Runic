#!/bin/bash

# Check script path here
SCRIPT_PATH=$(dirname $(realpath $0))

# Check if Lua exists on the PATH
LUA="$(which lua)"

if [ -z "${LUA}" ]; then
	echo "Error: Lua not found"
	echo "\tPlease install Lua and add it to your PATH"
	exit 1
fi

# Check if SCRIPT_PATH/runic.lua exists
RUNIC="${SCRIPT_PATH}/runic.lua"

if [ ! -f "${RUNIC}" ]; then
	echo "Downloading runic.lua..."

	RUNIC_UPDATE="${SCRIPT_PATH}/runic-update"

	if [ ! -f "${RUNIC-UPDATE}" ]; then
		echo "Error: runic-update not found"
		echo "\tPlease reinstall Runic"
		exit 1
	fi

	$SCRIPT_PATH/runic-update
fi

# Start the editor
$LUA "$RUNIC" "$@"
