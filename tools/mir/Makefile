PREFIX ?= ~/mir-inst

.PHONY: all
all:
	@ :

.PHONY: install
install:
	@mkdir -p $(PREFIX)/bin
	cp mir.in $(PREFIX)/bin/mir-xen
	for i in unix-direct unix-socket node; do \
	  ln -nf $(PREFIX)/bin/mir-xen $(PREFIX)/mir-$i; \
	done
	cp mir-run $(PREFIX)/bin/mir-run
	chmod 755 $(PREFIX)/bin/mir-xen $(PREFIX)/bin/mir-run
