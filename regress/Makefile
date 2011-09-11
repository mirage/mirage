.PHONY: clean all

JOBS ?= -j 5
OC=ocamlbuild $(JOBS)

all:
	$(OC) basic.run
	$(OC) lwt.run

clean:
	$(OC) -clean
