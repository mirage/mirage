## Process this file with automake to generate Makefile.in

AUTOMAKE_OPTIONS = cygnus dejagnu
ACLOCAL_AMFLAGS = -I . -I ..

# Multilib support variables.
MULTISRCTOP =
MULTIBUILDTOP =
MULTIDIRS =
MULTISUBDIR =
MULTIDO = true
MULTICLEAN = true

LIBTOOL_VERSION_INFO = 0:0:0

if NEWLIB_HW_FP
MATHDIR = mathfp
else
MATHDIR = math
endif

# Work around what appears to be a GNU make bug handling MAKEFLAGS
# values defined in terms of make variables, as is the case for CC and
# friends when we are called from the top level Makefile.
AM_MAKEFLAGS = \
	"AR_FLAGS=$(AR_FLAGS)" \
	"CC_FOR_BUILD=$(CC_FOR_BUILD)" \
	"CFLAGS=$(CFLAGS)" \
	"CCASFLAGS=$(CCASFLAGS)" \
	"CFLAGS_FOR_BUILD=$(CFLAGS_FOR_BUILD)" \
	"CFLAGS_FOR_TARGET=$(CFLAGS_FOR_TARGET)" \
	"INSTALL=$(INSTALL)" \
	"LDFLAGS=$(LDFLAGS)" \
	"LIBCFLAGS=$(LIBCFLAGS)" \
	"LIBCFLAGS_FOR_TARGET=$(LIBCFLAGS_FOR_TARGET)" \
	"MAKE=$(MAKE)" \
	"MAKEINFO=$(MAKEINFO) $(MAKEINFOFLAGS)" \
	"PICFLAG=$(PICFLAG)" \
	"PICFLAG_FOR_TARGET=$(PICFLAG_FOR_TARGET)" \
	"SHELL=$(SHELL)" \
	"EXPECT=$(EXPECT)" \
	"RUNTEST=$(RUNTEST)" \
	"RUNTESTFLAGS=$(RUNTESTFLAGS)" \
	"exec_prefix=$(exec_prefix)" \
	"infodir=$(infodir)" \
	"libdir=$(libdir)" \
	"prefix=$(prefix)" \
	"tooldir=$(tooldir)" \
	"top_toollibdir=$(toollibdir)" \
	"AR=$(AR)" \
	"AS=$(AS)" \
	"CC=$(CC_FOR_NEWLIB)" \
	"LD=$(LD)" \
	"LIBCFLAGS=$(LIBCFLAGS)" \
	"NM=$(NM)" \
	"PICFLAG=$(PICFLAG)" \
	"RANLIB=$(RANLIB)" \
	"DESTDIR=$(DESTDIR)"

FLAGS_TO_PASS=$(AM_MAKEFLAGS)

if HAVE_DOC
DOCDIR = doc
else
DOCDIR =
endif

SUBDIRS = libc libm \
	$(DOCDIR) . $(EXTRA_DIRS)

tooldir = $(exec_prefix)/$(host_alias)
toollibdir = $(tooldir)/lib$(MULTISUBDIR)

AR_FLAGS = rc

if USE_LIBTOOL
toollib_LTLIBRARIES = libm.la \
	libc.la
else
toollib_LIBRARIES = libm.a \
	libc.a
endif

noinst_DATA = stmp-targ-include

toollib_DATA = $(CRT0) $(CRT1)


# The functions ldexp, frexp and modf are traditionally supplied in
# both libc.a and libm.a.  We build them in libm.a and copy them over,
# along with some required supporting routines.
MATHOBJS_IN_LIBC = \
	$(lpfx)s_isinf.$(oext) $(lpfx)sf_isinf.$(oext) \
	$(lpfx)s_isnan.$(oext) $(lpfx)sf_isnan.$(oext) \
	$(lpfx)s_isinfd.$(oext) $(lpfx)sf_isinff.$(oext) \
	$(lpfx)s_isnand.$(oext) $(lpfx)sf_isnanf.$(oext) \
	$(lpfx)s_nan.$(oext) $(lpfx)sf_nan.$(oext) \
	$(lpfx)s_ldexp.$(oext) $(lpfx)sf_ldexp.$(oext) \
	$(lpfx)s_frexp.$(oext) $(lpfx)sf_frexp.$(oext) \
	$(lpfx)s_modf.$(oext) \
	$(lpfx)sf_modf.$(oext) $(lpfx)s_scalbn.$(oext) \
	$(lpfx)sf_scalbn.$(oext) \
	$(lpfx)s_finite.$(oext) $(lpfx)sf_finite.$(oext) \
	$(lpfx)s_copysign.$(oext) $(lpfx)sf_copysign.$(oext) \
	$(lpfx)s_infconst.$(oext)

LIBC_OBJECTLISTS = \
	$(POSIX_OBJECTLIST) \
	$(SIGNAL_OBJECTLIST) \
	$(SYSCALL_OBJECTLIST) \
	$(UNIX_OBJECTLIST) \
	$(STDIO64_OBJECTLIST) \
	libc/argz/objectlist.awk.in \
	libc/stdlib/objectlist.awk.in \
	libc/time/objectlist.awk.in \
	libc/ctype/objectlist.awk.in \
	libc/search/objectlist.awk.in \
	libc/string/objectlist.awk.in \
	libc/locale/objectlist.awk.in \
	libc/misc/objectlist.awk.in \
	libc/reent/objectlist.awk.in \
	libc/errno/objectlist.awk.in \
	libc/stdio/objectlist.awk.in \
	$(MACHINE_OBJECTLIST) \
	$(SYS_OBJECTLIST) \
	$(SYS_MACH_OBJECTLIST)

LIBM_OBJECTLISTS = \
	libm/$(MATHDIR)/objectlist.awk.in \
	libm/common/objectlist.awk.in \
	$(LIBM_MACHINE_OBJECTLIST)

libm_la_LDFLAGS = -version-info $(LIBTOOL_VERSION_INFO) -release newlib -no-undefined -Xcompiler -nostdlib -Xlinker --version-script=$(srcdir)/libc/sys/linux/shared.ld -lgcc -objectlist libm-libtool-objectlist

libc_la_LDFLAGS = -version-info $(LIBTOOL_VERSION_INFO) -release newlib -no-undefined -Xcompiler -nostdlib -Xlinker --version-script=$(srcdir)/libc/sys/linux/shared.ld -lgcc -objectlist libc-libtool-objectlist

if USE_LIBTOOL
libm_la_SOURCES =
libm_la_DEPENDENCIES = libm-libtool-objectlist

# objects listed later in LIBM_OBJECTLISTS will override those listed earlier
libm-libtool-objectlist: $(LIBM_OBJECTLISTS)
	cat $(LIBM_OBJECTLISTS) | $(AWK) '{ libm[$$1] = $$2 }; END { for (x in libm) printf ("%s\n", libm[x]) }' > $@

libc_la_SOURCES =
libc_la_DEPENDENCIES = libc-libtool-objectlist

# objects listed later in LIBM_OBJECTLISTS and LIBC_OBJECTLISTS will override those listed earlier
libc-libtool-objectlist: $(LIBM_OBJECTLISTS) $(LIBC_OBJECTLISTS)
	cat $(LIBM_OBJECTLISTS) $(LIBC_OBJECTLISTS) |  $(AWK) '{ libc[$$1] = $$2 }; END { for (x in libc) printf ("%s\n", libc[x]) }' > $@

else

libc.a: libc/libc.a libm.a
	rm -rf libc.a libg.a tmp
	mkdir tmp
	cd tmp; \
	 $(AR) x ../libm.a $(MATHOBJS_IN_LIBC) ; \
	 $(AR) x ../libc/libc.a ; \
	 $(AR) $(AR_FLAGS) ../$@ *.o
	$(RANLIB) libc.a
	ln libc.a libg.a >/dev/null 2>/dev/null || cp libc.a libg.a
	rm -rf tmp

libc/libc.a: ; @true

libm.a: libm/libm.a
	rm -f $@
	ln libm/libm.a $@ >/dev/null 2>/dev/null || cp libm/libm.a $@

libm/libm.a: ; @true

endif # USE_LIBTOOL

crt0.o: $(CRT0_DIR)$(CRT0)
	rm -f $@
	ln $(CRT0_DIR)$(CRT0) $@ >/dev/null 2>/dev/null \
	 || cp $(CRT0_DIR)$(CRT0) $@

$(CRT0_DIR)$(CRT0): ; @true

crt1.o: $(CRT1_DIR)$(CRT1)
	rm -f $@
	ln $(CRT0_DIR)$(CRT0) $@ >/dev/null 2>/dev/null \
	 || cp $(CRT0_DIR)$(CRT0) $@

$(CRT1_DIR)$(CRT1): ; @true


all-recursive: stmp-targ-include

# The targ-include directory just holds the includes files for the
# particular system and machine we have been configured for.  It is
# used while building.
stmp-targ-include: config.status
	-rm -rf targ-include stmp-targ-include
	mkdir targ-include targ-include/sys targ-include/machine targ-include/bits
	cp newlib.h targ-include/newlib.h
	-for i in $(srcdir)/libc/machine/$(machine_dir)/machine/*.h; do \
	    if [ -f $$i ]; then \
	      cp $$i targ-include/machine/`basename $$i`; \
	    else true; fi ; \
	  done
	-for i in $(srcdir)/libc/machine/$(machine_dir)/sys/*.h; do \
	    if [ -f $$i ]; then \
	      cp $$i targ-include/sys/`basename $$i`; \
	    else true; fi ; \
	  done
	-for i in $(srcdir)/libc/machine/$(machine_dir)/include/*.h; do \
	    if [ -f $$i ]; then \
	      cp $$i targ-include/`basename $$i`; \
	    else true; fi ; \
	  done
	-for i in $(srcdir)/libc/sys/$(sys_dir)/include/*.h; do \
	    if [ -f $$i ]; then \
	      cp $$i targ-include/`basename $$i`; \
	    else true; fi ; \
	  done
	-for i in $(srcdir)/libc/sys/$(sys_dir)/sys/*.h; do \
	    if [ -f $$i ]; then \
	      cp $$i targ-include/sys/`basename $$i`; \
	    else true; fi ; \
	  done
	-for i in $(srcdir)/libc/sys/$(sys_dir)/bits/*.h; do \
	    if [ -f $$i ]; then \
	      cp $$i targ-include/bits/`basename $$i`; \
	    else true; fi ; \
	  done
	-for i in $(srcdir)/libc/sys/$(sys_dir)/machine/*.h; do \
	    if [ -f $$i ]; then \
	      cp $$i targ-include/machine/`basename $$i`; \
	    else true; fi ; \
	  done
	-for i in $(srcdir)/libc/sys/$(sys_dir)/machine/$(machine_dir)/*.h; do \
	    if [ -f $$i ]; then \
	      cp $$i targ-include/machine/`basename $$i`; \
	    else true; fi ; \
	  done
	-for i in $(srcdir)/libc/sys/$(sys_dir)/machine/$(machine_dir)/include/*.h; do \
	    if [ -f $$i ]; then \
	      cp $$i targ-include/machine/`basename $$i`; \
	    else true; fi ; \
	  done
	touch $@

CLEANFILES = targ-include stmp-targ-include

install-data-local:	install-toollibLIBRARIES
if USE_LIBTOOL
else
	rm -f $(DESTDIR)$(toollibdir)/libg.a
	ln $(DESTDIR)$(toollibdir)/libc.a $(DESTDIR)$(toollibdir)/libg.a >/dev/null 2>/dev/null || cp $(DESTDIR)$(toollibdir)/libc.a $(DESTDIR)$(toollibdir)/libg.a
endif
	$(MULTIDO) $(AM_MAKEFLAGS) DO=install multi-do # $(MAKE)
	-if [ -z "$(MULTISUBDIR)" ]; then \
	  $(mkinstalldirs) $(DESTDIR)$(tooldir)/include; \
	  for i in $(srcdir)/libc/include/*.h; do \
	   $(INSTALL_DATA) $$i $(DESTDIR)$(tooldir)/include/`basename $$i`; \
	  done; \
	  $(INSTALL_DATA) newlib.h $(DESTDIR)$(tooldir)/include/newlib.h; \
	  $(mkinstalldirs) $(DESTDIR)$(tooldir)/include/machine; \
	  for i in $(srcdir)/libc/include/machine/*.h; do \
	   $(INSTALL_DATA) $$i $(DESTDIR)$(tooldir)/include/machine/`basename $$i`; \
	  done; \
	  for i in $(srcdir)/libc/machine/$(machine_dir)/machine/*.h; do \
	    if [ -f $$i ]; then \
	     $(INSTALL_DATA) $$i $(DESTDIR)$(tooldir)/include/machine/`basename $$i`; \
	    else true; fi ; \
	  done; \
	  $(mkinstalldirs) $(DESTDIR)$(tooldir)/include/sys; \
	  for i in $(srcdir)/libc/include/sys/*.h; do \
	   $(INSTALL_DATA) $$i $(DESTDIR)$(tooldir)/include/sys/`basename $$i`; \
	  done; \
	  for i in $(srcdir)/libc/machine/$(machine_dir)/sys/*.h; do \
	    if [ -f $$i ]; then \
	     $(INSTALL_DATA) $$i $(DESTDIR)$(tooldir)/include/sys/`basename $$i`; \
	    else true; fi ; \
	  done ; \
	  for i in $(srcdir)/libc/machine/$(machine_dir)/include/*.h; do \
	    if [ -f $$i ]; then \
	     $(INSTALL_DATA) $$i $(DESTDIR)$(tooldir)/include/`basename $$i`; \
	    else true; fi ; \
	  done ; \
	  for i in $(srcdir)/libc/sys/$(sys_dir)/sys/*.h; do \
	    if [ -f $$i ]; then \
	     $(INSTALL_DATA) $$i $(DESTDIR)$(tooldir)/include/sys/`basename $$i`; \
	    else true; fi ; \
	  done ; \
	  $(mkinstalldirs) $(DESTDIR)$(tooldir)/include/bits; \
	  for i in $(srcdir)/libc/sys/$(sys_dir)/bits/*.h; do \
	    if [ -f $$i ]; then \
	     $(INSTALL_DATA) $$i $(DESTDIR)$(tooldir)/include/bits/`basename $$i`; \
	    else true; fi ; \
	  done ; \
	  for i in $(srcdir)/libc/sys/$(sys_dir)/machine/*.h; do \
	    if [ -f $$i ]; then \
	     $(INSTALL_DATA) $$i $(DESTDIR)$(tooldir)/include/machine/`basename $$i`; \
	    else true; fi ; \
	  done ; \
	  for i in $(srcdir)/libc/sys/$(sys_dir)/include/*.h; do \
	    if [ -f $$i ]; then \
	     $(INSTALL_DATA) $$i $(DESTDIR)$(tooldir)/include/`basename $$i`; \
	    else true; fi ; \
	  done ; \
	  for i in $(srcdir)/libc/sys/$(sys_dir)/machine/$(machine_dir)/include/*.h; do \
	    if [ -f $$i ]; then \
	     $(INSTALL_DATA) $$i $(DESTDIR)$(tooldir)/include/machine/`basename $$i`; \
	    else true; fi ; \
	  done ; \
	else true; fi

# Force makedoc to be built before building info files.
info-recursive: doc/makedoc
dvi-recursive: doc/makedoc
doc/makedoc:
	cd doc && $(MAKE) all

CONFIG_STATUS_DEPENDENCIES = $(newlib_basedir)/configure.host

# Multilib support.
.PHONY: all-multi check-multi mostlyclean-multi clean-multi distclean-multi \
	maintainer-clean-multi

all-recursive: all-multi
check-recursive: check-multi
mostlyclean-recursive: mostlyclean-multi
clean-recursive: clean-multi
distclean-recursive: distclean-multi
maintainer-clean-recursive: maintainer-clean-multi

# The $(MAKE) comments below are to enable parallel building.
all-multi:
	$(MULTIDO) $(AM_MAKEFLAGS) DO=all multi-do # $(MAKE)
check-multi:
	$(MULTIDO) $(AM_MAKEFLAGS) DO=check multi-do # $(MAKE)
mostlyclean-multi:
	$(MULTICLEAN) $(AM_MAKEFLAGS) DO=mostlyclean multi-clean # $(MAKE)
clean-multi:
	$(MULTICLEAN) $(AM_MAKEFLAGS) DO=clean multi-clean # $(MAKE)
distclean-multi:
	$(MULTICLEAN) $(AM_MAKEFLAGS) DO=distclean multi-clean # $(MAKE)
maintainer-clean-multi:
	$(MULTICLEAN) $(AM_MAKEFLAGS) DO=maintainer-clean multi-clean # $(MAKE)

MAKEOVERRIDES=

# dejagnu support

RUNTESTFLAGS=

site.exp: Makefile
	@echo 'Making a new site.exp file...'
	@test ! -f site.bak || rm -f site.bak
	@echo '## these variables are automatically generated by make ##' > $@-t
	@echo '# Do not edit here.  If you wish to override these values' >> $@-t
	@echo '# edit the last section' >> $@-t
	@echo 'set tool $(DEJATOOL)' >> $@-t
	@echo 'set tool_version $(VERSION)' >> $@-t
	@echo 'set srcdir $(srcdir)/testsuite' >> $@-t
	@echo 'set objdir' `pwd` >> $@-t
	@echo 'set tmpdir' `pwd`/testsuite >> $@-t
	@echo 'set multibuildtop ./$(MULTIBUILDTOP)' >> $@-t
	@echo 'set host_alias $(build_alias)' >> $@-t
	@echo 'set host_triplet $(build_triplet)' >> $@-t
	@echo 'set target_alias $(host_alias)' >> $@-t
	@echo 'set target_triplet $(host_triplet)' >> $@-t
	@echo '## All variables above are generated by configure. Do Not Edit ##' >> $@-t
	@test ! -f site.exp || sed '1,/^## All variables above are.*##/ d' site.exp >> $@-t
	@test ! -f site.exp || mv site.exp site.bak
	@mv $@-t site.exp

check-DEJAGNU: site.exp
	@if [ -d testsuite ] ; then \
	  true ; \
	else \
	  mkdir testsuite ; \
	fi
	@rm -f testsuite/site.exp
	@cp site.exp testsuite/site.exp
	@rootme=`pwd` ; \
	export rootme ; \
	srcdir=`cd ${srcdir}; pwd` ; \
	export srcdir ; \
	EXPECT=`if [ -f $${rootme}/${MULTIBUILDTOP}../../expect/expect ] ; then \
	          echo $${rootme}/${MULTIBUILDTOP}../../expect/expect ; \
	        else \
	          echo expect ; \
	        fi` ; \
	export EXPECT ; \
	echo "Found expect: $${EXPECT}" ; \
	if [ -f $(top_builddir)/$(MULTIBUILDTOP)../../expect/expect ] ; then \
	  TCL_LIBRARY=`cd $(top_srcdir)/../tcl/library && pwd` ; \
	  export TCL_LIBRARY ; \
	  echo "Found TCL library directory: $${TCL_LIBRARY}" ; \
	fi ; \
	RUNTEST=`if [ -f $${srcdir}/../dejagnu/runtest ] ; then \
	           echo $${srcdir}/../dejagnu/runtest ; \
	         else \
	           echo runtest ; \
	         fi` ; \
	export RUNTEST ; \
	echo "Found runtest: $${RUNTEST}" ; \
	cd testsuite ; \
	if $(SHELL) -c "$$RUNTEST --version" > /dev/null 2>&1 ; then \
	   $$RUNTEST --tool $(DEJATOOL) --srcdir $${srcdir}/testsuite $(RUNTESTFLAGS) ; \
	   : ; \
	else \
	   echo "WARNING: could not find \`runtest'" 1>&2 ; \
	fi
