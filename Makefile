.PHONY: all clean doc test

all:
	dune build

clean:
	dune clean

doc:
	dune build @doc

test:
	dune runtest
