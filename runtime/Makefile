OS=$(shell uname -s)

all:
	if [ "$(OS)" = "Linux" ]; then cd xen && $(MAKE); fi
	cd unix && $(MAKE)

clean:
	if [ "$(OS)" = "Linux" ]; then cd xen && $(MAKE) clean; fi
	cd unix && $(MAKE) clean
