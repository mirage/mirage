# build main app
OCAMLDIR=$(shell ocamlc -where)
CFLAGS=-I $(OCAMLDIR) -O2

SOURCES=main
CS=$(SOURCES:%=%.c)
OBJS=$(SOURCES:%=%.o)
LIBS=-lmirage_unix -lasmrun -lbigarray -lm -lcamlstr
LDFLAGS=-L.. -L$(OCAMLDIR)
APP_LIB ?= null.o

.PHONY: app
app: $(OBJS) $(APP_LIB)
	@$(CC) $(CFLAGS) $(LDFLAGS) -o $@ $(OBJS) $(APP_LIB) $(LIBS)

%.o: %.c
	@$(CC) -c -O2 $(CFLAGS) -o $@ $<

.PHONY: clean
clean:
	rm -f *.o *.a app
