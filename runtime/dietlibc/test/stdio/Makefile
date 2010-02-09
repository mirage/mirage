DIET=diet
CC=gcc
CFLAGS=-Wall -nostdinc
LCOMPAT=-lcompat

all: stdiotest tstgetln

TESTPROGRAMS=tst-ferror tstdiomisc tst-fdopen tst-fileno \
tst-fphex tst-fseek tst-printf tstscanf tst-sprintf tst-sscanf tst-tmpnam \
tst-unbputc tst-ungetc

stdiotest: $(TESTPROGRAMS)

%: %.c
	$(DIET) $(CC) $(CFLAGS) $^ -o $@

tstgetln: tstgetln.c
	$(DIET) $(CC) $(CFLAGS) $^ $(LCOMPAT) -o $@

clean:
	rm -f $(TESTPROGRAMS) tstgetln


