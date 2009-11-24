XEN_ROOT = ../..

include $(XEN_ROOT)/Config.mk

all: main.a

main.a: main.o 
	$(AR) cr $@ $^

clean:
	rm -f *.a *.o
