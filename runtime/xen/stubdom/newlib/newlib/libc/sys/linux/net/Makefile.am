## Process this file with automake to generate Makefile.in

AUTOMAKE_OPTIONS = cygnus

INCLUDES = -I$(srcdir)/../include $(NEWLIB_CFLAGS) $(CROSS_CFLAGS) $(TARGET_CFLAGS)

GENERAL_SOURCES = addr2ascii.c ascii2addr.c base64.c bindresvport.c ether_addr.c getaddrinfo.c \
	gethostbydns.c gethostbyht.c gethostbynis.c gethostnamadr.c \
	getifaddrs.c getnameinfo.c \
	getnetbydns.c getnetbyht.c getnetbynis.c getnetnamadr.c \
	getproto.c getprotoent.c getprotoname.c getservbyname.c \
	getservbyport.c getservent.c herror.c hesiod.c inet_addr.c \
	ifname.c inet_lnaof.c \
	inet_makeaddr.c inet_net_ntop.c inet_net_pton.c inet_neta.c \
	inet_netof.c inet_network.c inet_ntoa.c inet_ntop.c \
	inet_pton.c innetgr-stub.c ip6opt.c issetugid-stub.c \
        linkaddr.c map_v4v6.c namespace.h un-namespace.h \
	name6.c ns_addr.c \
	ns_name.c ns_netint.c \
	ns_ntoa.c ns_parse.c ns_print.c ns_ttl.c \
	nsdispatch.c nslexer.c nsparser.c nsparser.h \
	nsap_addr.c res_comp.c res_data.c res_debug.c \
	res_init.c res_mkquery.c res_mkupdate.c res_query.c \
	res_send.c res_update.c rthdr.c vars.c

ELIX_4_SOURCES = \
	rcmd.$(oext) \
	rcmdsh.$(oext)

if ELIX_LEVEL_1
ELIX_SOURCES =
else
if ELIX_LEVEL_2
ELIX_SOURCES =
else
if ELIX_LEVEL_3
ELIX_SOURCES =
else
ELIX_SOURCES = $(ELIX_4_SOURCES)
endif
endif
endif

libnet_la_LDFLAGS = -Xcompiler -nostdlib
libnet_la_CFLAGS = -DINET6

if USE_LIBTOOL
noinst_LTLIBRARIES = libnet.la
libnet_la_SOURCES = $(GENERAL_SOURCES) $(ELIX_SOURCES)
noinst_DATA = objectlist.awk.in
else
noinst_LIBRARIES = lib.a
lib_a_SOURCES = $(GENERAL_SOURCES) $(ELIX_SOURCES)
lib_a_CFLAGS = $(AM_CFLAGS)
noinst_DATA =
endif # USE_LIBTOOL

include $(srcdir)/../../../../Makefile.shared

install-data-local:
	$(mkinstalldirs) $(DESTDIR)$(tooldir)/include/arpa; \
	for i in $(srcdir)/../include/arpa/*.h; do \
	  $(INSTALL_DATA) $$i $(DESTDIR)$(tooldir)/include/arpa/`basename $$i`; \
	done; \
	$(mkinstalldirs) $(DESTDIR)$(tooldir)/include/net; \
	for i in $(srcdir)/../include/net/*.h; do \
	  $(INSTALL_DATA) $$i $(DESTDIR)$(tooldir)/include/net/`basename $$i`; \
	done; \
	$(mkinstalldirs) $(DESTDIR)$(tooldir)/include/netinet; \
	for i in $(srcdir)/../include/netinet/*.h; do \
	  $(INSTALL_DATA) $$i $(DESTDIR)$(tooldir)/include/netinet/`basename $$i`; \
	done; \
	$(mkinstalldirs) $(DESTDIR)$(tooldir)/include/netinet6; \
	for i in $(srcdir)/../include/netinet6/*.h; do \
	  $(INSTALL_DATA) $$i $(DESTDIR)$(tooldir)/include/netinet6/`basename $$i`; \
	done; \
	$(mkinstalldirs) $(DESTDIR)$(tooldir)/include/netns; \
	for i in $(srcdir)/../include/netns/*.h; do \
	  $(INSTALL_DATA) $$i $(DESTDIR)$(tooldir)/include/netns/`basename $$i`; \
	done; \
	$(mkinstalldirs) $(DESTDIR)$(tooldir)/include/rpc; \
	for i in $(srcdir)/../include/rpc/*.h; do \
	  $(INSTALL_DATA) $$i $(DESTDIR)$(tooldir)/include/rpc/`basename $$i`; \
	done;
