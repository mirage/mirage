.PHONY: all clean
.DEFAULT: all

SUDO ?= sudo
export SUDO

all:
	@cd stdlib && $(MAKE)

clean:
	@cd stdlib && $(MAKE) clean

install:
	@cd stdlib && $(MAKE) install
