#ifndef __XEN_SHARED_H__
#define __XEN_SHARED_H__

#include <xen/config.h>

#ifdef CONFIG_COMPAT

#include <compat/xen.h>

typedef union {
    struct shared_info native;
    struct compat_shared_info compat;
} shared_info_t;

/*
 * Compat field is never larger than native field, so cast to that as it
 * is the largest memory range it is safe for the caller to modify without
 * further discrimination between compat and native cases.
 */
#define __shared_info(d, s, field)                      \
    (*(!has_32bit_shinfo(d) ?                           \
       (typeof(&(s)->compat.field))&(s)->native.field : \
       (typeof(&(s)->compat.field))&(s)->compat.field))

typedef union {
    struct vcpu_info native;
    struct compat_vcpu_info compat;
} vcpu_info_t;

/* As above, cast to compat field type. */
#define __vcpu_info(v, i, field)                        \
    (*(!has_32bit_shinfo((v)->domain) ?                 \
       (typeof(&(i)->compat.field))&(i)->native.field : \
       (typeof(&(i)->compat.field))&(i)->compat.field))

#else

typedef struct shared_info shared_info_t;
#define __shared_info(d, s, field) ((s)->field)

typedef struct vcpu_info vcpu_info_t;
#define __vcpu_info(v, i, field)   ((i)->field)

#endif

extern vcpu_info_t dummy_vcpu_info;

#define shared_info(d, field)      __shared_info(d, (d)->shared_info, field)
#define vcpu_info(v, field)        __vcpu_info(v, (v)->vcpu_info, field)

#endif /* __XEN_SHARED_H__ */
