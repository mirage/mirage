XEN_ROOT = ../..
include $(XEN_ROOT)/tools/Rules.mk

.PHONY: all
all: xen-foreign xen/.dir

.PHONY: xen-foreign
xen-foreign:
	$(MAKE) -C xen-foreign

xen/.dir:
	@rm -rf xen
	mkdir -p xen/libelf
	ln -sf ../$(XEN_ROOT)/xen/include/public/COPYING xen
	ln -sf $(addprefix ../,$(wildcard $(XEN_ROOT)/xen/include/public/*.h)) xen
	ln -sf $(addprefix ../$(XEN_ROOT)/xen/include/public/,arch-ia64 arch-x86 hvm io xsm) xen
	ln -sf ../xen-sys/$(XEN_OS) xen/sys
	ln -sf $(addprefix ../../$(XEN_ROOT)/xen/include/xen/,libelf.h elfstructs.h) xen/libelf/
	ln -s ../xen-foreign xen/foreign
	touch $@

.PHONY: install
install: all
	$(INSTALL_DIR) $(DESTDIR)$(INCLUDEDIR)/xen/arch-ia64
	$(INSTALL_DIR) $(DESTDIR)$(INCLUDEDIR)/xen/arch-ia64/hvm
	$(INSTALL_DIR) $(DESTDIR)$(INCLUDEDIR)/xen/arch-x86
	$(INSTALL_DIR) $(DESTDIR)$(INCLUDEDIR)/xen/arch-x86/hvm
	$(INSTALL_DIR) $(DESTDIR)$(INCLUDEDIR)/xen/foreign
	$(INSTALL_DIR) $(DESTDIR)$(INCLUDEDIR)/xen/hvm
	$(INSTALL_DIR) $(DESTDIR)$(INCLUDEDIR)/xen/io
	$(INSTALL_DIR) $(DESTDIR)$(INCLUDEDIR)/xen/sys
	$(INSTALL_DIR) $(DESTDIR)$(INCLUDEDIR)/xen/xsm
	$(INSTALL_DATA) xen/COPYING $(DESTDIR)$(INCLUDEDIR)/xen
	$(INSTALL_DATA) xen/*.h $(DESTDIR)$(INCLUDEDIR)/xen
	$(INSTALL_DATA) xen/arch-ia64/*.h $(DESTDIR)$(INCLUDEDIR)/xen/arch-ia64
	$(INSTALL_DATA) xen/arch-ia64/hvm/*.h $(DESTDIR)$(INCLUDEDIR)/xen/arch-ia64/hvm
	$(INSTALL_DATA) xen/arch-x86/*.h $(DESTDIR)$(INCLUDEDIR)/xen/arch-x86
	$(INSTALL_DATA) xen/arch-x86/hvm/*.h $(DESTDIR)$(INCLUDEDIR)/xen/arch-x86/hvm
	$(INSTALL_DATA) xen/foreign/*.h $(DESTDIR)$(INCLUDEDIR)/xen/foreign
	$(INSTALL_DATA) xen/hvm/*.h $(DESTDIR)$(INCLUDEDIR)/xen/hvm
	$(INSTALL_DATA) xen/io/*.h $(DESTDIR)$(INCLUDEDIR)/xen/io
	$(INSTALL_DATA) xen/sys/*.h $(DESTDIR)$(INCLUDEDIR)/xen/sys
	$(INSTALL_DATA) xen/xsm/*.h $(DESTDIR)$(INCLUDEDIR)/xen/xsm

.PHONY: clean
clean:
	rm -rf xen
	$(MAKE) -C xen-foreign clean

