PREFIX=/usr/local
BINDIR=$(PREFIX)/bin

all: build

configure:
	obuild configure

dist/setup: configure

build: dist/setup
	obuild build

install: build
	cp dist/build/mirari/mirari $(BINDIR)

.PHONY: clean
clean:
	obuild clean
