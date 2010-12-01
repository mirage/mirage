PREFIX ?= ~/mir-inst

.PHONY: all
all:
	@ :

.PHONY: install
install:
	mkdir -p $(PREFIX)/bin
	sed -e 's,@MIRAGELIB@,$(PREFIX)/mirage,g' < mir.in > $(PREFIX)/bin/mir
	chmod 755 $(PREFIX)/bin/mir

clean:
	@ :

include $(OCAMLMAKEFILE)
