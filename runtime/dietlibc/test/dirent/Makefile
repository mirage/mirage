DIET=diet
CC=gcc
CFLAGS=-Wall

all: dirent

TESTPROGRAMS=opendir-tst1 tst-seekdir

dirent: $(TESTPROGRAMS)

%: %.c
	$(DIET) $(CC) $(CFLAGS) $^ -o $@

clean:
	rm -f $(TESTPROGRAMS)

