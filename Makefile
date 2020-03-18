.PHONY: all clean doc test

all:
	dune build

clean:
	dune clean

doc:
	dune build @doc

test:
	dune runtest
	INSIDE_FUNCTORIA_TESTS=1 dune exec -- test/functoria/e2e/test.exe
