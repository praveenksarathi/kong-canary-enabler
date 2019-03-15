DEV_ROCKS = busted luacheck

.PHONY: install dev clean doc lint test coverage

install:
	luarocks make tantem-canary-enabler-*.rockspec \

dev: install
	@for rock in $(DEV_ROCKS) ; do \
		if ! command -v $$rock > /dev/null ; then \
		echo $$rock not found, installing via luarocks... ; \
			luarocks install $$rock ; \
		else \
			echo $$rock already installed, skipping ; \
		fi \
	done;

lint:
	@luacheck -q .


test: dev \
      lint
	./test.sh
