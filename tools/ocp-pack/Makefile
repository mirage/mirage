.PHONY: all tar

INSTALL_DIR=$(shell which ocaml | cut -d / -f 0-4)
FILES   = version.ml pack.ml
TARGET  = ocp-pack

all: $(FILES)
	ocamlopt version.ml pack.ml -o ocp-pack

install:
	cp ocp-pack $(INSTALL_DIR)

uninstall:
	rm -f $(INSTALL_DIR)/ocp-pack

clean:
	rm -f *.o *.cmi *.cmx
