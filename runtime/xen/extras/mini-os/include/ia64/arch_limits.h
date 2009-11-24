
#ifndef __ARCH_LIMITS_H__
#define __ARCH_LIMITS_H__

/* Commonly 16K pages are used. */
#define __PAGE_SHIFT	14	/* 16K pages */
#define __PAGE_SIZE	(1<<(__PAGE_SHIFT))

#define __STACK_SIZE_PAGE_ORDER   2
#define __STACK_SIZE              (__PAGE_SIZE * (1 << __STACK_SIZE_PAGE_ORDER))
          
#endif /* __ARCH_LIMITS_H__ */
