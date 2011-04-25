CC=gcc
DEFS=  
PROGNAME= mir-fs-create mir-fs-extract
INCLUDES=  -I.
LIBS=

DEFINES= $(INCLUDES) $(DEFS)
CFLAGS= -g $(DEFINES) -std=gnu99 -D_GNU_SOURCE -Wall

SRCS = fsutil.c create.c extract.c  

CREAT_OBJS = fsutil.o create.o
EXTRACT_OBJS = fsutil.o extract.o
OBJS = $(CREAT_OBJS) $(EXTRACT_OBJS)

.c.o:
	$(CC) $(CFLAGS) -c $*.c

all: $(PROGNAME)

mir-fs-create : $(CREAT_OBJS)
	$(CC) $(CFLAGS) -o $@ $(CREAT_OBJS) $(LIBS)

mir-fs-extract : $(EXTRACT_OBJS)
	$(CC) $(CFLAGS) -o $@ $(EXTRACT_OBJS) $(LIBS)

clean:
	rm -f $(OBJS) $(PROGNAME) core *~
