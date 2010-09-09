.PHONY: build
build:
	if [ ! -d ocamljs ]; then git clone http://github.com/jaked/ocamljs.git; fi
	rsync -a ../../runtime/xen/base/ocaml .
	cd ocamljs && ./configure -srcdir ../ocaml -srcdir-lwt ../../lib/lwt && $(MAKE) && $(MAKE) install

.PHONY: clean
clean:
	rm -rf ocamljs ocaml
