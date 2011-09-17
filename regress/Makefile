.PHONY: clean all

JOBS ?= -j 5
OC=ocamlbuild $(JOBS)

all:
	$(OC) basic.run
	$(OC) lwt.run
	$(OC) block.run

clean:
	$(OC) -clean
