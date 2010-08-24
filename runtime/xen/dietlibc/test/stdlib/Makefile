DIET=diet
CC=gcc

CFLAGS=-Wall -nostdinc

all: stdlibtest

TESTPROGRAMS=test-canon testdiv testrand testsort tst-calloc \
tst-environ tst-limits tst-malloc tst-rand48 tst-strtod tst-strtol \
tst-strtoll tst-system

stdlibtest: $(TESTPROGRAMS)
%: %.c
	$(DIET) $(CC) $(CFLAGS) $^ -o $@

clean:
	rm -f $(TESTPROGRAMS)

