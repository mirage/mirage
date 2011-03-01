CC=gcc
DEFS=  
PROGNAME= create extract
INCLUDES=  -I.
LIBS=

DEFINES= $(INCLUDES) $(DEFS)
CFLAGS= -g $(DEFINES)

SRCS = fsutil.c create.c extract.c  

CREAT_OBJS = fsutil.o create.o
EXTRACT_OBJS = fsutil.o extract.o
OBJS = $(CREAT_OBJS) $(EXTRACT_OBJS)

.c.o:
	$(CC) $(CFLAGS) -c $*.c

all: $(PROGNAME)

create : $(CREAT_OBJS)
	$(CC) $(CFLAGS) -o create $(CREAT_OBJS) $(LIBS)

extract : $(EXTRACT_OBJS)
	$(CC) $(CFLAGS) -o extract $(EXTRACT_OBJS) $(LIBS)

clean:
	rm -f $(OBJS) $(PROGNAME) core *~
