STDLIBS=stdlib stdlib.js lwt mpl
PLATFORM=xen unix browser 
LIBS=mlnet mletherip mludp mltcp mldhcp mldns

ALL=$(STDLIBS) $(PLATFORM) $(LIBS)

.PHONY: all
all:
	set -e; for i in $(ALL); do (cd $$i && $(MAKE)); done

.PHONY: clean
clean:
	set -e; for i in $(ALL); do (cd $$i && $(MAKE) clean); done

.PHONY: install
install:
	@ :
