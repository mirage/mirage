XEN_ROOT=../../..
include $(XEN_ROOT)/tools/Rules.mk

ROOT = $(XEN_ROOT)/xen/include/public

architectures := x86_32 x86_64 ia64
headers := $(patsubst %, %.h, $(architectures))

.PHONY: all clean check-headers
all: $(headers) check-headers

clean:
	rm -f $(headers)
	rm -f checker checker.c
	rm -f *.pyc *.o *~

checker: checker.c $(headers)
	$(HOSTCC) $(HOSTCFLAGS) -o $@ $<

check-headers: checker
	./checker > tmp.size
	diff -u reference.size tmp.size
	rm tmp.size

x86_32.h: mkheader.py structs.py $(ROOT)/arch-x86/xen-x86_32.h $(ROOT)/arch-x86/xen.h $(ROOT)/xen.h
	$(PYTHON) $< $* $@ $(filter %.h,$^)

x86_64.h: mkheader.py structs.py $(ROOT)/arch-x86/xen-x86_64.h $(ROOT)/arch-x86/xen.h $(ROOT)/xen.h
	$(PYTHON) $< $* $@ $(filter %.h,$^)

ia64.h: mkheader.py structs.py $(ROOT)/arch-ia64.h $(ROOT)/xen.h
	$(PYTHON) $< $* $@ $(filter %.h,$^)

checker.c: mkchecker.py structs.py
	$(PYTHON) $< $@ $(architectures)
