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

if [ -z "${RUNIC}" ]; then
	echo "Error: runic.lua not found"
	echo "\tPlease reinstall Runic, or manually copy runic.lua to the same directory as this script"
	exit 1
fi

$LUA "$RUNIC" "$@"
