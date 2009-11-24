
#ifndef __XEN_PAGING_H__
#define __XEN_PAGING_H__

#include <xen/config.h>

#if defined CONFIG_PAGING_ASSISTANCE

#include <asm/paging.h>
#include <asm/p2m.h>

#elif defined CONFIG_SHADOW

#include <asm/shadow.h>

#define paging_mode_translate(d)  shadow_mode_translate(d)
#define paging_mode_external(d)   (0)

#else

#define paging_mode_translate(d)              (0)
#define paging_mode_external(d)               (0)
#define guest_physmap_add_page(d, p, m, o)    (0)
#define guest_physmap_remove_page(d, p, m, o) ((void)0)

#endif

#endif /* __XEN_PAGING_H__ */
