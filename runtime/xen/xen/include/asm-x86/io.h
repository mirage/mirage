#ifndef _ASM_IO_H
#define _ASM_IO_H

#include <xen/config.h>
#include <xen/types.h>
#include <asm/page.h>

/* We don't need real ioremap() on Xen/x86. */
#define ioremap(x,l) (__va(x))
#define iounmap(p)   ((void)0)

#define readb(x) (*(volatile char *)(x))
#define readw(x) (*(volatile short *)(x))
#define readl(x) (*(volatile int *)(x))
#define writeb(d,x) (*(volatile char *)(x) = (d))
#define writew(d,x) (*(volatile short *)(x) = (d))
#define writel(d,x) (*(volatile int *)(x) = (d))

#define __OUT1(s,x) \
static inline void out##s(unsigned x value, unsigned short port) {

#define __OUT2(s,s1,s2) \
__asm__ __volatile__ ("out" #s " %" s1 "0,%" s2 "1"

#define __OUT(s,s1,x) \
__OUT1(s,x) __OUT2(s,s1,"w") : : "a" (value), "Nd" (port)); } \
__OUT1(s##_p,x) __OUT2(s,s1,"w") : : "a" (value), "Nd" (port));} 

#define __IN1(s) \
static inline RETURN_TYPE in##s(unsigned short port) { RETURN_TYPE _v;

#define __IN2(s,s1,s2) \
__asm__ __volatile__ ("in" #s " %" s2 "1,%" s1 "0"

#define __IN(s,s1,i...) \
__IN1(s) __IN2(s,s1,"w") : "=a" (_v) : "Nd" (port) ,##i ); return _v; } \
__IN1(s##_p) __IN2(s,s1,"w") : "=a" (_v) : "Nd" (port) ,##i ); return _v; } 

#define RETURN_TYPE unsigned char
__IN(b,"")
#undef RETURN_TYPE
#define RETURN_TYPE unsigned short
__IN(w,"")
#undef RETURN_TYPE
#define RETURN_TYPE unsigned int
__IN(l,"")
#undef RETURN_TYPE

__OUT(b,"b",char)
__OUT(w,"w",short)
__OUT(l,,int)

extern void (*pv_post_outb_hook)(unsigned int port, u8 value);

#endif
