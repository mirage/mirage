ARCH=xen
export ARCH

.PHONY: all
all:
	cd lib_test && $(MAKE)

.PHONY: echo
echo:
	cd lib && ./echop

.PHONY: clean
clean:
	cd lib && $(MAKE) clean
	cd lib_test && $(MAKE) clean
