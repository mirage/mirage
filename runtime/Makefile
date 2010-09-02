OS=$(shell uname -s)

TARGS=unix
ifeq ($(OS).$(ARCH),Linux.x86_64)
  TARGS+=xen
endif

all:
	for i in $(TARGS); do cd $$i && $(MAKE); done

clean:
	for i in $(TARGS); do cd $$i && $(MAKE) clean; done
