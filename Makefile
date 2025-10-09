all: build

build:
	bin/glue bin/srlua runic.lua runic
	chmod +x runic

test: build
	./runic runic.lua

install: build
	@echo
	@echo Installing to /usr/bin...
	@echo Please provide the superuser password
	@sudo cp ./runic /usr/bin/runic
	@echo

uninstall:
	@echo
	@echo Removing /usr/bin/runic
	@echo Please provide the superuser password
	@sudo rm -f /usr/bin/runic
	@echo

clean:
	rm -f ./runic
