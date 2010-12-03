PREFIX ?= ~/mir-inst

.PHONY: all
all:
	@ :

.PHONY: install
install:
	mkdir -p $(PREFIX)/bin
	sed -e 's,@MIRAGELIB@,$(PREFIX)/mirage,g' -e 's,@MIRAGEOS@,unix,g' < mir.in > $(PREFIX)/bin/mir-unix
	sed -e 's,@MIRAGELIB@,$(PREFIX)/mirage,g' -e 's,@MIRAGEOS@,xen,g' < mir.in > $(PREFIX)/bin/mir-xen
	chmod 755 $(PREFIX)/bin/mir-unix $(PREFIX)/bin/mir-xen

clean:
	@ :

include $(OCAMLMAKEFILE)
