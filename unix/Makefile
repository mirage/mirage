.PHONY: all _config build install doc clean

all: build

_config:
	./cmd configure unix

build: _config
	./cmd build

install:
	./cmd install

doc: _config
	./cmd doc

clean:
	./cmd clean
