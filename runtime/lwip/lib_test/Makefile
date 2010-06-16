#
# Copyright (c) 2001, 2002 Swedish Institute of Computer Science.
# All rights reserved. 
# 
# Redistribution and use in source and binary forms, with or without modification, 
# are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice,
#    this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright notice,
#    this list of conditions and the following disclaimer in the documentation
#    and/or other materials provided with the distribution.
# 3. The name of the author may not be used to endorse or promote products
#    derived from this software without specific prior written permission. 
#
# THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR IMPLIED 
# WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF 
# MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT 
# SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, 
# EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT 
# OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS 
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN 
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING 
# IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY 
# OF SUCH DAMAGE.
#
# This file is part of the lwIP TCP/IP stack.
# 
# Author: Adam Dunkels <adam@sics.se>
#

ROOTDIR=$(abspath ../../..)
include $(ROOTDIR)/mk/xen.mk
 
CCDEP=gcc
CC=gcc
#To compile for linux: make ARCH=linux
#To compile for cygwin: make ARCH=cygwin
#To compile for openbsd: make ARCH=openbsd
#To compile for xen: make ARCH=xen
ARCH=xen
CFLAGS +=-g -Wall -pedantic -D$(ARCH) -DIPv4 -DLWIP_DEBUG
ARFLAGS=rs

LWIPARCH=.

#Set this to where you have the lwip core module checked out from CVS
#default assumes it's a dir named lwip at the same level as the contrib module
LWIPDIR=../lwip/src

CFLAGS:=$(CFLAGS) \
	-I$(LWIPDIR)/include -I$(LWIPARCH)/include -I$(LWIPDIR)/include/ipv4  -I.

# COREFILES, CORE4FILES: The minimum set of files needed for lwIP.
COREFILES=$(LWIPDIR)/core/mem.c $(LWIPDIR)/core/memp.c $(LWIPDIR)/core/netif.c \
	$(LWIPDIR)/core/pbuf.c $(LWIPDIR)/core/raw.c \
	$(LWIPDIR)/core/stats.c $(LWIPDIR)/core/sys.c \
        $(LWIPDIR)/core/tcp.c $(LWIPDIR)/core/tcp_in.c \
        $(LWIPDIR)/core/tcp_out.c $(LWIPDIR)/core/udp.c $(LWIPDIR)/core/dhcp.c \
	$(LWIPDIR)/core/init.c
CORE4FILES=$(LWIPDIR)/core/ipv4/icmp.c $(LWIPDIR)/core/ipv4/ip.c \
	$(LWIPDIR)/core/ipv4/inet.c $(LWIPDIR)/core/ipv4/ip_addr.c \
	$(LWIPDIR)/core/ipv4/ip_frag.c $(LWIPDIR)/core/ipv4/inet_chksum.c 

# NETIFFILES: Files implementing various generic network interface functions.'
NETIFFILES=$(LWIPDIR)/netif/etharp.c xen-tapif.c

# LWIPFILES: All the above.
LWIPFILES=$(COREFILES) $(CORE4FILES) $(NETIFFILES)
LWIPFILESW=$(wildcard $(LWIPFILES))
LWIPOBJS=$(notdir $(LWIPFILESW:.c=.o))

LWIPLIB=liblwip4.a

.PHONY: all
all: .depend $(LWIPLIB)
	@ :

%.o:
	$(CC) $(CFLAGS) -c $(<:.o=.c)

clean:
	rm -f *.o $(LWIPLIB) $(APPLIB) echop .depend* *.core core

depend dep: .depend

include .depend

$(LWIPLIB): $(LWIPOBJS)
	$(AR) $(ARFLAGS) $(LWIPLIB) $?

.depend: $(LWIPFILES) $(APPFILES)
	$(CCDEP) $(CFLAGS) -MM $^ > .depend || rm -f .depend



