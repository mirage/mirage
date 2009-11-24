/*
 * lwipopts.h
 *
 * Configuration for lwIP running on mini-os 
 *
 * Tim Deegan <Tim.Deegan@eu.citrix.net>, July 2007
 */

#ifndef __LWIP_LWIPOPTS_H__
#define __LWIP_LWIPOPTS_H__

#define SYS_LIGHTWEIGHT_PROT 1
#define MEM_LIBC_MALLOC 1
#define LWIP_TIMEVAL_PRIVATE 0
#define LWIP_DHCP 1
#define LWIP_COMPAT_SOCKETS 0
#define LWIP_IGMP 1
#define LWIP_USE_HEAP_FROM_INTERRUPT 1
#define MEMP_NUM_SYS_TIMEOUT 10
#define TCP_SND_BUF 3000
#define TCP_MSS 1500

#endif /* __LWIP_LWIPOPTS_H__ */
