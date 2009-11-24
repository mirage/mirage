/******************************************************************************
 * xenoprof.h
 * 
 * Xenoprof: Xenoprof enables performance profiling in Xen
 * 
 * Copyright (C) 2005 Hewlett-Packard Co.
 * written by Aravind Menon & Jose Renato Santos
 */

#ifndef __XEN_XENOPROF_H__
#define __XEN_XENOPROF_H__

#include <xen/config.h>
#include <public/xenoprof.h>
#include <asm/xenoprof.h>

#define XENOPROF_DOMAIN_IGNORED    0
#define XENOPROF_DOMAIN_ACTIVE     1
#define XENOPROF_DOMAIN_PASSIVE    2

#define XENOPROF_IDLE              0
#define XENOPROF_INITIALIZED       1
#define XENOPROF_COUNTERS_RESERVED 2
#define XENOPROF_READY             3
#define XENOPROF_PROFILING         4

#ifndef CONFIG_COMPAT
typedef struct xenoprof_buf xenoprof_buf_t;
#else
#include <compat/xenoprof.h>
typedef union {
	struct xenoprof_buf native;
	struct compat_oprof_buf compat;
} xenoprof_buf_t;
#endif

struct xenoprof_vcpu {
    int event_size;
    xenoprof_buf_t *buffer;
};

struct xenoprof {
    char *rawbuf;
    int npages;
    int nbuf;
    int bufsize;
    int domain_type;
    int domain_ready;
    int is_primary;
#ifdef CONFIG_COMPAT
    int is_compat;
#endif
    struct xenoprof_vcpu *vcpu;
};

#ifndef CONFIG_COMPAT
#define XENOPROF_COMPAT(x) 0
#define xenoprof_buf(d, b, field) ((b)->field)
#else
#define XENOPROF_COMPAT(x) ((x)->is_compat)
#define xenoprof_buf(d, b, field) (*(!(d)->xenoprof->is_compat ? \
                                       &(b)->native.field : \
                                       &(b)->compat.field))
#endif

struct domain;
int is_active(struct domain *d);
int is_passive(struct domain *d);
void free_xenoprof_pages(struct domain *d);

int xenoprof_add_trace(struct domain *d, struct vcpu *v, 
                       unsigned long eip, int mode);

#define PMU_OWNER_NONE          0
#define PMU_OWNER_XENOPROF      1
#define PMU_OWNER_HVM           2
int acquire_pmu_ownship(int pmu_ownership);
void release_pmu_ownship(int pmu_ownership);

void xenoprof_log_event(struct vcpu *vcpu,
                        struct cpu_user_regs * regs, unsigned long eip,
                        int mode, int event);

#endif  /* __XEN__XENOPROF_H__ */
