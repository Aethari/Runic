#!/bin/bash

# Check if Lua exists on the PATH
LUA="$(which lua)"

if [ -z "${LUA}" ]; then
	echo "Error: Lua not found"
	echo "\tPlease install Lua and add it to your PATH"
	exit 1
fi

# Check if ./runic.lua exists
RUNIC="./runic.lua"

if [ ! -f "${RUNIC}" ]; then
	echo "Downloading runic.lua..."

	RUNIC_UPDATE="./runic-update"

	if [ ! -f "${RUNIC-UPDATE}" ]; then
		echo "Error: runic-update not found"
		echo "\tPlease reinstall Runic"
		exit 1
	fi

	./runic-update
fi

# Start the editor
$LUA "$RUNIC" "$@"
