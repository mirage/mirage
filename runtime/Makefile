ROOTDIR=../
include $(ROOTDIR)/mk/base.mk

TARGS=unix
ifeq ($(OS).$(ARCH),linux.x86_64)
  TARGS+=xen
endif

all:
	for i in $(TARGS); do (cd $$i && $(MAKE)); done

clean:
	for i in $(TARGS); do (cd $$i && $(MAKE) clean); done
