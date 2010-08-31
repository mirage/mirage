.PHONY: all
all:
	cd stdlib && $(MAKE)
	cd mpl && $(MAKE)
	cd lwt && $(MAKE)
	cd xen && $(MAKE)
	cd unix && $(MAKE)
	cd mlnet && $(MAKE)
	cd dns && $(MAKE)
	rm -rf obj
	mkdir obj
	cd obj && for i in mpl xen unix mlnet dns; do ln -nfs ../$$i/$$i.cmx; ln -nfs ../$$i/$$i.cmi; ln -nfs ../$$i/$$i.o; done

.PHONY: clean
clean:
	cd stdlib && $(MAKE) clean
	cd mpl && $(MAKE) clean
	cd lwt && $(MAKE) clean
	cd xen && $(MAKE) clean
	cd unix && $(MAKE) clean
	cd mlnet && $(MAKE) clean
	cd dns && $(MAKE) clean
	rm -rf obj

.PHONY: install
install:
	@ :
