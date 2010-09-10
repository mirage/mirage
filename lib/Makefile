.PHONY: all
all:
	cd stdlib && $(MAKE)
	cd mpl && $(MAKE)
	cd lwt && $(MAKE)
	cd xen && $(MAKE)
	cd browser && $(MAKE)
	cd unix && $(MAKE)
	cd mlnet && $(MAKE)
	cd dns && $(MAKE)

.PHONY: clean
clean:
	cd stdlib && $(MAKE) clean
	cd mpl && $(MAKE) clean
	cd lwt && $(MAKE) clean
	cd xen && $(MAKE) clean
	cd unix && $(MAKE) clean
	cd browser && $(MAKE) clean
	cd mlnet && $(MAKE) clean
	cd dns && $(MAKE) clean

.PHONY: install
install:
	@ :
