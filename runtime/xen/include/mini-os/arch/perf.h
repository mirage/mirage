/* 
 * lwip/arch/perf.h
 *
 * Arch-specific performance measurement for lwIP running on mini-os 
 *
 * Tim Deegan <Tim.Deegan@eu.citrix.net>, July 2007
 */

#ifndef __LWIP_ARCH_PERF_H__
#define __LWIP_ARCH_PERF_H__

#define PERF_START    do { } while(0)
#define PERF_STOP(_x) do { (void)(_x); } while (0)

#endif /* __LWIP_ARCH_PERF_H__ */
