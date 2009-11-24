XEN_ROOT = ../..
include $(XEN_ROOT)/tools/Rules.mk

MAJOR    = 3.4
MINOR    = 0

CTRL_SRCS-y       :=
CTRL_SRCS-y       += xc_core.c
CTRL_SRCS-$(CONFIG_X86) += xc_core_x86.c
CTRL_SRCS-$(CONFIG_IA64) += xc_core_ia64.c
CTRL_SRCS-y       += xc_domain.c
CTRL_SRCS-y       += xc_evtchn.c
CTRL_SRCS-y       += xc_misc.c
CTRL_SRCS-y       += xc_acm.c
CTRL_SRCS-y       += xc_flask.c
CTRL_SRCS-y       += xc_physdev.c
CTRL_SRCS-y       += xc_private.c
CTRL_SRCS-y       += xc_sedf.c
CTRL_SRCS-y       += xc_csched.c
CTRL_SRCS-y       += xc_tbuf.c
CTRL_SRCS-y       += xc_pm.c
CTRL_SRCS-y       += xc_cpu_hotplug.c
CTRL_SRCS-y       += xc_resume.c
CTRL_SRCS-y       += xc_tmem.c
CTRL_SRCS-$(CONFIG_X86) += xc_pagetab.c
CTRL_SRCS-$(CONFIG_Linux) += xc_linux.c
CTRL_SRCS-$(CONFIG_SunOS) += xc_solaris.c
CTRL_SRCS-$(CONFIG_X86_Linux) += xc_ptrace.c xc_ptrace_core.c
CTRL_SRCS-$(CONFIG_NetBSD) += xc_netbsd.c
CTRL_SRCS-$(CONFIG_MiniOS) += xc_minios.c

GUEST_SRCS-y :=
GUEST_SRCS-y += xg_private.c xc_suspend.c
GUEST_SRCS-$(CONFIG_MIGRATE) += xc_domain_restore.c xc_domain_save.c
GUEST_SRCS-$(CONFIG_MIGRATE) += xc_offline_page.c
GUEST_SRCS-$(CONFIG_HVM) += xc_hvm_build.c

vpath %.c ../../xen/common/libelf
CFLAGS += -I../../xen/common/libelf

GUEST_SRCS-y += libelf-tools.c libelf-loader.c
GUEST_SRCS-y += libelf-dominfo.c libelf-relocate.c

# new domain builder
GUEST_SRCS-y                 += xc_dom_core.c xc_dom_boot.c
GUEST_SRCS-y                 += xc_dom_elfloader.c
GUEST_SRCS-$(CONFIG_X86)     += xc_dom_bzimageloader.c
GUEST_SRCS-y                 += xc_dom_binloader.c
GUEST_SRCS-y                 += xc_dom_compat_linux.c

GUEST_SRCS-$(CONFIG_X86)     += xc_dom_x86.c
GUEST_SRCS-$(CONFIG_X86)     += xc_cpuid_x86.c
GUEST_SRCS-$(CONFIG_IA64)    += xc_dom_ia64.c

-include $(XEN_TARGET_ARCH)/Makefile

CFLAGS   += -Werror -Wmissing-prototypes
CFLAGS   += $(INCLUDES) -I. -I../xenstore -I../include

# Needed for posix_fadvise64() in xc_linux.c
CFLAGS-$(CONFIG_Linux) += -D_GNU_SOURCE

# Define this to make it possible to run valgrind on code linked with these
# libraries.
#CFLAGS   += -DVALGRIND -O0 -ggdb3

LDFLAGS  += -L.

CTRL_LIB_OBJS := $(patsubst %.c,%.o,$(CTRL_SRCS-y))
CTRL_PIC_OBJS := $(patsubst %.c,%.opic,$(CTRL_SRCS-y))

GUEST_LIB_OBJS := $(patsubst %.c,%.o,$(GUEST_SRCS-y))
GUEST_PIC_OBJS := $(patsubst %.c,%.opic,$(GUEST_SRCS-y))

LIB := libxenctrl.a
ifneq ($(stubdom),y)
LIB += libxenctrl.so libxenctrl.so.$(MAJOR) libxenctrl.so.$(MAJOR).$(MINOR)
endif

LIB += libxenguest.a
ifneq ($(stubdom),y)
LIB += libxenguest.so libxenguest.so.$(MAJOR) libxenguest.so.$(MAJOR).$(MINOR)
endif

.PHONY: all
all: build

.PHONY: build
build:
	$(MAKE) libs

.PHONY: libs
libs: $(LIB)

.PHONY: install
install: build
	$(INSTALL_DIR) $(DESTDIR)$(LIBDIR)
	$(INSTALL_DIR) $(DESTDIR)$(INCLUDEDIR)
	$(INSTALL_PROG) libxenctrl.so.$(MAJOR).$(MINOR) $(DESTDIR)$(LIBDIR)
	$(INSTALL_DATA) libxenctrl.a $(DESTDIR)$(LIBDIR)
	ln -sf libxenctrl.so.$(MAJOR).$(MINOR) $(DESTDIR)$(LIBDIR)/libxenctrl.so.$(MAJOR)
	ln -sf libxenctrl.so.$(MAJOR) $(DESTDIR)$(LIBDIR)/libxenctrl.so
	$(INSTALL_DATA) xenctrl.h $(DESTDIR)$(INCLUDEDIR)

	$(INSTALL_PROG) libxenguest.so.$(MAJOR).$(MINOR) $(DESTDIR)$(LIBDIR)
	$(INSTALL_DATA) libxenguest.a $(DESTDIR)$(LIBDIR)
	ln -sf libxenguest.so.$(MAJOR).$(MINOR) $(DESTDIR)$(LIBDIR)/libxenguest.so.$(MAJOR)
	ln -sf libxenguest.so.$(MAJOR) $(DESTDIR)$(LIBDIR)/libxenguest.so
	$(INSTALL_DATA) xenguest.h $(DESTDIR)$(INCLUDEDIR)

.PHONY: TAGS
TAGS:
	etags -t *.c *.h

.PHONY: clean
clean:
	rm -rf *.rpm $(LIB) *~ $(DEPS) \
            $(CTRL_LIB_OBJS) $(CTRL_PIC_OBJS) \
            $(GUEST_LIB_OBJS) $(GUEST_PIC_OBJS)

.PHONY: rpm
rpm: build
	rm -rf staging
	mkdir staging
	mkdir staging/i386
	rpmbuild --define "staging$$PWD/staging" --define '_builddir.' \
		--define "_rpmdir$$PWD/staging" -bb rpm.spec
	mv staging/i386/*.rpm .
	rm -rf staging

# libxenctrl

libxenctrl.a: $(CTRL_LIB_OBJS)
	$(AR) rc $@ $^

libxenctrl.so: libxenctrl.so.$(MAJOR)
	ln -sf $< $@
libxenctrl.so.$(MAJOR): libxenctrl.so.$(MAJOR).$(MINOR)
	ln -sf $< $@

libxenctrl.so.$(MAJOR).$(MINOR): $(CTRL_PIC_OBJS)
	$(CC) $(CFLAGS) $(LDFLAGS) -Wl,$(SONAME_LDFLAG) -Wl,libxenctrl.so.$(MAJOR) $(SHLIB_CFLAGS) -o $@ $^ $(PTHREAD_LIBS)

# libxenguest

libxenguest.a: $(GUEST_LIB_OBJS)
	$(AR) rc $@ $^

libxenguest.so: libxenguest.so.$(MAJOR)
	ln -sf $< $@
libxenguest.so.$(MAJOR): libxenguest.so.$(MAJOR).$(MINOR)
	ln -sf $< $@

ifeq ($(CONFIG_MiniOS),y)
zlib-options =
else
zlib-options = $(shell					\
	(. ../check/funcs.sh;				\
	 if has_header bzlib.h; then			\
           echo "-DHAVE_BZLIB";				\
	   echo "-lbz2";				\
	 fi;						\
	 if has_header lzma.h; then			\
	   echo "-DHAVE_LZMA";				\
	   echo "-llzma";				\
	 fi) | grep $(1))
endif

xc_dom_bzimageloader.o: CFLAGS += $(call zlib-options,D)
xc_dom_bzimageloader.opic: CFLAGS += $(call zlib-options,D)

libxenguest.so.$(MAJOR).$(MINOR): LDFLAGS += $(call zlib-options,l)
libxenguest.so.$(MAJOR).$(MINOR): $(GUEST_PIC_OBJS) libxenctrl.so
	$(CC) $(CFLAGS) $(LDFLAGS) -Wl,$(SONAME_LDFLAG) -Wl,libxenguest.so.$(MAJOR) $(SHLIB_CFLAGS) -o $@ $(GUEST_PIC_OBJS) -lz -lxenctrl $(PTHREAD_LIBS)

-include $(DEPS)

