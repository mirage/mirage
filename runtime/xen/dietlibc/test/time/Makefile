DIET=diet
CC=gcc
CFLAGS=-Wall

all: timetest

TESTPROGRAMS=tst-strptime tst-mktime tst-posixtz tst-strftime

timetest: $(TESTPROGRAMS)

%: %.c
	$(DIET) $(CC) $(CFLAGS) $^ -o $@

clean:
	rm -f $(TESTPROGRAMS)

