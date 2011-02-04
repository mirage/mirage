PREFIX ?= ~/mir-inst

.PHONY: all
all:
	@ :

.PHONY: install
install:
	mkdir -p $(PREFIX)/bin
	sed -e 's,@MIRAGELIB@,$(PREFIX),g' -e 's,@MIRAGEOS@,xen,g' -e 's,@MIRAGEFLOW@,direct,g' < mir.in > $(PREFIX)/bin/mir-xen
	sed -e 's,@MIRAGELIB@,$(PREFIX),g' -e 's,@MIRAGEOS@,unix,g' -e 's,@MIRAGEFLOW@,direct,g' < mir.in > $(PREFIX)/bin/mir-unix-direct
	sed -e 's,@MIRAGELIB@,$(PREFIX),g' -e 's,@MIRAGEOS@,unix,g' -e 's,@MIRAGEFLOW@,socket,g' < mir.in > $(PREFIX)/bin/mir-unix-socket
	chmod 755 $(PREFIX)/bin/mir-unix-direct $(PREFIX)/bin/mir-unix-socket $(PREFIX)/bin/mir-xen

clean:
	@ :

include $(OCAMLMAKEFILE)
