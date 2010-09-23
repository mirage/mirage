STDLIBS=stdlib stdlib.js lwt mpl mlnet
PLATFORM=xen unix browser 
LIBS=mletherip mludp mltcp mldhcp mldns cohttp

ALL=$(STDLIBS) $(PLATFORM) $(LIBS)

.PHONY: all
all:
	set -e; for i in $(ALL); do (set -e; cd $$i && $(MAKE)); done

.PHONY: clean
clean:
	set -e; for i in $(ALL); do (set -e; cd $$i && $(MAKE) clean); done

.PHONY: install
install:
	@ :
