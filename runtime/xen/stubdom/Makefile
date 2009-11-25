XEN_ROOT = ..
MINI_OS = $(XEN_ROOT)/extras/mini-os

export XEN_OS=MiniOS

export stubdom=y
export debug=y
include $(XEN_ROOT)/Config.mk

GNU_TARGET_ARCH:=$(XEN_TARGET_ARCH)
ifeq ($(XEN_TARGET_ARCH),x86_32)
GNU_TARGET_ARCH:=i686
endif

ifeq ($(GNU_TARGET_ARCH), i686)
TARGET_CFLAGS=
NEWLIB_CFLAGS+=-D_I386MACH_ALLOW_HW_INTERRUPTS
STUBDOM_SUPPORTED=1
endif
ifeq ($(GNU_TARGET_ARCH), x86_64)
TARGET_CFLAGS=-mno-red-zone
NEWLIB_CFLAGS+=-D_I386MACH_ALLOW_HW_INTERRUPTS
STUBDOM_SUPPORTED=1
endif
ifeq ($(GNU_TARGET_ARCH), ia64)
TARGET_CFLAGS=-mconstant-gp
endif

CROSS_ROOT=cross-root-$(GNU_TARGET_ARCH)
CROSS_PREFIX=$(CURDIR)/$(CROSS_ROOT)

# Disable PIE/SSP if GCC supports them. They can break us.
TARGET_CFLAGS += $(CFLAGS)
TARGET_CPPFLAGS += $(CPPFLAGS)
TARGET_CFLAGS += $(call cc-option,$(CC),-nopie,)
TARGET_CFLAGS += $(call cc-option,$(CC),-fno-stack-protector,)
TARGET_CFLAGS += $(call cc-option,$(CC),-fno-stack-protector-all,)

# Do not use host headers and libs
GCC_INSTALL = $(shell LANG=C gcc -print-search-dirs | sed -n -e 's/install: \(.*\)/\1/p')
TARGET_CPPFLAGS += -U __linux__ -U __FreeBSD__ -U __sun__
TARGET_CPPFLAGS += -nostdinc
TARGET_CPPFLAGS += -isystem $(CURDIR)/$(MINI_OS)/include/posix
TARGET_CPPFLAGS += -isystem $(CROSS_PREFIX)/$(GNU_TARGET_ARCH)-xen-elf/include
TARGET_CPPFLAGS += -isystem $(GCC_INSTALL)include
TARGET_CPPFLAGS += -isystem $(CURDIR)/lwip/src/include
TARGET_CPPFLAGS += -isystem $(CURDIR)/lwip/src/include/ipv4
TARGET_CPPFLAGS += -I$(CURDIR)/include
TARGET_CPPFLAGS += -I$(XEN_ROOT)/xen/include

TARGET_LDFLAGS += -nostdlib -L$(CROSS_PREFIX)/$(GNU_TARGET_ARCH)-xen-elf/lib

TARGETS=c caml

##############
# Cross-newlib
##############

NEWLIB_STAMPFILE=$(CROSS_ROOT)/$(GNU_TARGET_ARCH)-xen-elf/lib/libc.a
.PHONY: cross-newlib
cross-newlib: $(NEWLIB_STAMPFILE)
$(NEWLIB_STAMPFILE): mk-headers-$(XEN_TARGET_ARCH)
	mkdir -p newlib-$(XEN_TARGET_ARCH)
	( cd newlib-$(XEN_TARGET_ARCH) && \
	  CC_FOR_TARGET="$(CC) $(TARGET_CPPFLAGS) $(TARGET_CFLAGS) $(NEWLIB_CFLAGS)" AR_FOR_TARGET=$(AR) LD_FOR_TARGET=$(LD) RANLIB_FOR_TARGET=$(RANLIB) ../newlib/configure --prefix=$(CROSS_PREFIX) --verbose --target=$(GNU_TARGET_ARCH)-xen-elf --enable-newlib-io-long-long --disable-multilib --disable-newlib-multithread && \
	  $(MAKE) && \
	  DESTDIR= $(MAKE) install )

############
# Cross-zlib
############

ZLIB_STAMPFILE=$(CROSS_ROOT)/$(GNU_TARGET_ARCH)-xen-elf/lib/libz.a
.PHONY: cross-zlib
cross-zlib: $(ZLIB_STAMPFILE)
$(ZLIB_STAMPFILE): zlib $(NEWLIB_STAMPFILE)
	( cd $< && \
	  CFLAGS="$(TARGET_CPPFLAGS) $(TARGET_CFLAGS)" CC=$(CC) ./configure --prefix=$(CROSS_PREFIX)/$(GNU_TARGET_ARCH)-xen-elf && \
	  $(MAKE) libz.a && \
	  $(MAKE) install )

#############
# Cross-ocaml
#############

CAMLLIB = $(CROSS_PREFIX)/$(GNU_TARGET_ARCH)-xen-elf/lib/ocaml
OCAML_STAMPFILE=$(CAMLLIB)/.dirstamp
OCAMLXEN_STAMPFILE=$(CAMLLIB)/libasmrunxen.a

MINIOS_HASNOT=HAS_IPV6 HAS_INET_ATON POSIX_SIGNALS HAS_GETRUSAGE HAS_STACK_OVERFLOW_DETECTION HAS_TIMES

.PHONY: cross-ocaml
cross-ocaml: $(OCAMLXEN_STAMPFILE)
$(OCAML_STAMPFILE): 
	@echo $(TARGET_LDFLAGS)
	cd ocaml && ./configure -prefix $(CROSS_PREFIX)/$(GNU_TARGET_ARCH)-xen-elf \
		-no-pthread -no-shared-libs -no-tk -no-curses \
		-cc "$(CC) -U_FORTIFY_SOURCE -fno-stack-protector"
	$(foreach i,$(MINIOS_HASNOT),sed -i 's,^\(#define $(i)\),//\1,' ocaml/config/s.h ; )
	$(MAKE) -C ocaml world
	$(MAKE) -C ocaml opt
	$(MAKE) -C ocaml install
	touch $@

$(OCAMLXEN_STAMPFILE): $(OCAML_STAMPFILE)
	$(MAKE) -C ocaml/asmrun clean
	$(MAKE) LDFLAGS="$(TARGET_LDFLAGS)" TARGET_CFLAGS="$(TARGET_CPPFLAGS) $(TARGET_CFLAGS)" \
	  -C ocaml/asmrun -f Makefile.xen libasmrun.a
	cp ocaml/asmrun/libasmrun.a $@

#######
# Links
#######

.PHONY: $(CROSS_ROOT)
$(CROSS_ROOT): cross-newlib cross-zlib 

mk-headers-$(XEN_TARGET_ARCH):
	mkdir -p include/xen && \
          ln -sf $(addprefix ../../,$(wildcard $(XEN_ROOT)/xen/include/public/*.h)) include/xen && \
          ln -sf $(addprefix ../../$(XEN_ROOT)/xen/include/public/,arch-ia64 arch-x86 hvm io xsm) include/xen && \
          ( [ -h include/xen/sys ] || ln -sf ../../$(XEN_ROOT)/tools/include/xen-sys/MiniOS include/xen/sys ) && \
          ( [ -h include/xen/libelf ] || ln -sf ../../$(XEN_ROOT)/tools/include/xen/libelf include/xen/libelf ) && \
	  mkdir -p include/xen-foreign && \
	  ln -sf $(addprefix ../../,$(wildcard $(XEN_ROOT)/tools/include/xen-foreign/*)) include/xen-foreign/ && \
	  $(MAKE) -C include/xen-foreign/ && \
	  ( [ -h include/xen/foreign ] || ln -sf ../xen-foreign include/xen/foreign )
	mkdir -p libxc-$(XEN_TARGET_ARCH)
	[ -h libxc-$(XEN_TARGET_ARCH)/Makefile ] || ( cd libxc-$(XEN_TARGET_ARCH) && \
	  ln -sf ../$(XEN_ROOT)/tools/libxc/*.h . && \
	  ln -sf ../$(XEN_ROOT)/tools/libxc/*.c . && \
	  ln -sf ../$(XEN_ROOT)/tools/libxc/Makefile . )
	mkdir -p libxc-$(XEN_TARGET_ARCH)/$(XEN_TARGET_ARCH)
	[ -h libxc-$(XEN_TARGET_ARCH)/$(XEN_TARGET_ARCH) ] || ( cd libxc-$(XEN_TARGET_ARCH)/$(XEN_TARGET_ARCH) && \
	  ln -sf ../$(XEN_ROOT)/tools/libxc/$(XEN_TARGET_ARCH)/*.c . && \
	  ln -sf ../$(XEN_ROOT)/tools/libxc/$(XEN_TARGET_ARCH)/*.h . && \
	  ln -sf ../$(XEN_ROOT)/tools/libxc/$(XEN_TARGET_ARCH)/Makefile . )
	$(MAKE) -C $(MINI_OS) links
	touch mk-headers-$(XEN_TARGET_ARCH)

TARGETS_MINIOS=$(addprefix mini-os-$(XEN_TARGET_ARCH)-,$(TARGETS))
$(TARGETS_MINIOS): mini-os-%:
	[ -d $@ ] || \
	for i in $$(cd $(MINI_OS) ; find . -type d) ; do \
                mkdir -p $@/$$i ; \
	done

#######
# libxc
#######

.PHONY: libxc
libxc: libxc-$(XEN_TARGET_ARCH)/libxenctrl.a libxc-$(XEN_TARGET_ARCH)/libxenguest.a
libxc-$(XEN_TARGET_ARCH)/libxenctrl.a libxc-$(XEN_TARGET_ARCH)/libxenguest.a:: cross-zlib
	CPPFLAGS="$(TARGET_CPPFLAGS)" CFLAGS="$(TARGET_CFLAGS)" $(MAKE) -C libxc-$(XEN_TARGET_ARCH)

######
# caml
######

.PHONY: caml
caml: $(CROSS_ROOT)
	CPPFLAGS="$(TARGET_CPPFLAGS)" CFLAGS="$(TARGET_CFLAGS)" $(MAKE) -C $@ LWIPDIR=$(CURDIR)/lwip OCAMLC_CROSS_PREFIX=$(CROSS_PREFIX)/$(GNU_TARGET_ARCH)-xen-elf/bin/

###
# C
###

.PHONY: c
c: $(CROSS_ROOT)
	CPPFLAGS="$(TARGET_CPPFLAGS)" CFLAGS="$(TARGET_CFLAGS)" $(MAKE) -C $@ LWIPDIR=$(CURDIR)/lwip

######
# Grub
######

grub-$(GRUB_VERSION).tar.gz:
	$(WGET) $(GRUB_URL)/$@

grub-upstream: grub-$(GRUB_VERSION).tar.gz
	tar xzf $<
	mv grub-$(GRUB_VERSION) $@
	for i in grub.patches/* ; do \
		patch -d $@ -p1 < $$i ; \
	done

.PHONY: grub
grub: grub-upstream $(CROSS_ROOT)
	mkdir -p grub-$(XEN_TARGET_ARCH)
	CPPFLAGS="$(TARGET_CPPFLAGS)" CFLAGS="$(TARGET_CFLAGS)" $(MAKE) -C $@ OBJ_DIR=$(CURDIR)/grub-$(XEN_TARGET_ARCH)

########
# minios
########

.PHONY: caml-stubdom
caml-stubdom: mini-os-$(XEN_TARGET_ARCH)-caml libxc caml
	DEF_CPPFLAGS="$(TARGET_CPPFLAGS)" DEF_CFLAGS="-DCONFIG_CAML $(TARGET_CFLAGS)" DEF_LDFLAGS="$(TARGET_LDFLAGS)" $(MAKE) -C $(MINI_OS) OBJ_DIR=$(CURDIR)/$< LWIPDIR=$(CURDIR)/lwip APP_OBJS="$(CURDIR)/caml/main-caml.o $(CURDIR)/caml/caml.o $(CAMLLIB)/libasmrunxen.a"

.PHONY: c-stubdom
c-stubdom: mini-os-$(XEN_TARGET_ARCH)-c c
	DEF_CPPFLAGS="$(TARGET_CPPFLAGS)" DEF_CFLAGS="-DCONFIG_C $(TARGET_CFLAGS)" DEF_LDFLAGS="$(TARGET_LDFLAGS)" $(MAKE) -C $(MINI_OS) OBJ_DIR=$(CURDIR)/$< LWIPDIR=$(CURDIR)/lwip APP_OBJS=$(CURDIR)/c/main.a

#######
# clean
#######

.PHONY: clean
clean:
	rm -fr mini-os-$(XEN_TARGET_ARCH)-c
	rm -fr mini-os-$(XEN_TARGET_ARCH)-caml
	$(MAKE) -C caml clean
	$(MAKE) -C c clean
	$(MAKE) -C ocaml clean
	[ ! -d libxc-$(XEN_TARGET_ARCH) ] || $(MAKE) -C libxc-$(XEN_TARGET_ARCH) clean

# clean the cross-compilation result
.PHONY: crossclean
crossclean: clean
	rm -fr $(CROSS_ROOT)
	rm -fr newlib-$(XEN_TARGET_ARCH)
	rm -fr zlib-$(XEN_TARGET_ARCH)
	rm -fr libxc-$(XEN_TARGET_ARCH)
	rm -fr ocaml-$(XEN_TARGET_ARCH)
	rm -fr include
	rm -f mk-headers-*

# clean patched sources
.PHONY: patchclean
patchclean: crossclean
	rm -fr newlib-$(NEWLIB_VERSION)
	rm -fr lwip-$(XEN_TARGET_ARCH)
	rm -fr grub-upstream

# clean downloads
.PHONY: downloadclean
downloadclean: patchclean
	rm -f newlib-$(NEWLIB_VERSION).tar.gz
	rm -f zlib-$(ZLIB_VERSION).tar.gz
	rm -f pciutils-$(LIBPCI_VERSION).tar.bz2
	rm -f grub-$(GRUB_VERSION).tar.gz
	rm -f lwip-$(LWIP_VERSION).tar.gz
	rm -f ocaml-$(OCAML_VERSION).tar.gz

.PHONY: distclean
distclean: downloadclean
