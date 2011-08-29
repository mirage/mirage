PREFIX ?= ~/mir-inst

.PHONY: all
all:
	@ :

.PHONY: install
install:
	@mkdir -p $(PREFIX)/bin
	sed -e 's,@MIRAGELIB@,$(PREFIX),g' < mir.in > $(PREFIX)/bin/mir-build
	cp mir-run $(PREFIX)/bin/mir-run
	chmod 755 $(PREFIX)/bin/mir-build $(PREFIX)/bin/mir-run
