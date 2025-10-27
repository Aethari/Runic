all: test

test:
	lua runic.lua runic.lua 2> error.log

read-log:
	@chmod +x scripts/cat-log.sh
	@scripts/cat-log.sh

install:
	@echo
	@echo "Please provide the superuser password"
	@sudo echo "Installing to \"/usr/bin/runic\""
	@echo

	sudo cp runic.lua /usr/bin/runic.lua
	sudo cp scripts/runic.sh /usr/bin/runic
	sudo cp scripts/runic-update.sh /usr/bin/runic-update

	sudo chmod +x /usr/bin/runic
	sudo chmod +x /usr/bin/runic-update

	@echo

uninstall:
	@echo
	@echo "Removing /usr/bin/runic, /usr/bin/runic-update, and /usr/bin/runic.lua"
	@echo "Please provide the superuser password"

	sudo rm -f /usr/bin/runic
	sudo rm -f /usr/bin/runic-update
	sudo rm -f /usr/bin/runic.lua

	@echo

clean:
	rm -f ./runic
