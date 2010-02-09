DIET=diet
CC=gcc
CFLAGS=-Wall

TESTPROGRAMS=test_ifindex tst-gethnm tst-ntoa
# tst-network does not link w diet libc
all: inet 
	
inet: $(TESTPROGRAMS)	

%: %.c
	$(DIET) $(CC) $(CFLAGS) $^ -o $@

clean:
	rm -f $(TESTPROGRAMS)


