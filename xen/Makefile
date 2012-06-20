.PHONY: all clean depend install

OCAMLFIND ?= ocamlfind

XEN_INCLUDE = $(shell ocamlfind printconf path)/mirage/include/xen

all: 
	./cmd configure xen
	./cmd build

install:
	./cmd install
	mkdir -p $(XEN_INCLUDE)
	cp -r runtime/include/* $(XEN_INCLUDE)

clean:
	./cmd clean
