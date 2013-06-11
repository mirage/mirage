PREFIX=/usr/local
BINDIR=$(PREFIX)/bin

all: build

configure:
	obuild configure --annot

dist/setup: configure

build: dist/setup
	obuild build

install:
	cp dist/build/mirari/mirari $(BINDIR)

.PHONY: clean
clean:
	obuild clean
