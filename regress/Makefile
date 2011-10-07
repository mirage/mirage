.PHONY: clean all

JOBS ?= -j 5
MB=mir-build $(JOBS)

all:
	$(MB) basic.run
	$(MB) lwt.run
	$(MB) block.run
	$(MB) regexps.run

clean:
	# not mir-build as might be cleaning entire install, and have lost
	# mir-build
	ocamlbuild -clean 
