/****************************************************************
 * acm_core.h 
 * 
 * Copyright (C) 2005 IBM Corporation
 *
 * Author:
 * Reiner Sailer <sailer@watson.ibm.com>
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License as
 * published by the Free Software Foundation, version 2 of the
 * License.
 *
 * sHype header file describing core data types and constants
 *    for the access control module and relevant policies
 *
 */

#ifndef _ACM_CORE_H
#define _ACM_CORE_H

#include <xen/spinlock.h>
#include <xen/list.h>
#include <public/xsm/acm.h>
#include <public/xsm/acm_ops.h>
#include <xsm/acm/acm_endian.h>

#define ACM_DEFAULT_SECURITY_POLICY \
        ACM_CHINESE_WALL_AND_SIMPLE_TYPE_ENFORCEMENT_POLICY

/* Xen-internal representation of the binary policy */
struct acm_binary_policy {
    char *policy_reference_name;
    u16 primary_policy_code;
    u16 secondary_policy_code;
    struct acm_policy_version xml_pol_version;
    u8 xml_policy_hash[ACM_SHA1_HASH_SIZE];
};

struct chwall_binary_policy {
    u32 max_types;
    u32 max_ssidrefs;
    u32 max_conflictsets;
    domaintype_t *ssidrefs;     /* [max_ssidrefs][max_types]  */
    domaintype_t *conflict_aggregate_set;  /* [max_types]      */
    domaintype_t *running_types;    /* [max_types]      */
    domaintype_t *conflict_sets;   /* [max_conflictsets][max_types]*/
};

struct ste_binary_policy {
    u32 max_types;
    u32 max_ssidrefs;
    domaintype_t *ssidrefs;     /* [max_ssidrefs][max_types]  */
    atomic_t ec_eval_count, gt_eval_count;
    atomic_t ec_denied_count, gt_denied_count;
    atomic_t ec_cachehit_count, gt_cachehit_count;
};

/* global acm policy */
extern u16 acm_active_security_policy;
extern struct acm_binary_policy acm_bin_pol;
extern struct chwall_binary_policy chwall_bin_pol;
extern struct ste_binary_policy ste_bin_pol;
/* use the lock when reading / changing binary policy ! */
extern rwlock_t acm_bin_pol_rwlock;
extern rwlock_t ssid_list_rwlock;

/* subject and object type definitions */
#define ACM_DATATYPE_domain 1

/* defines number of access decisions to other domains can be cached
 * one entry per domain, TE does not distinguish evtchn or grant_table */
#define ACM_TE_CACHE_SIZE 8
#define ACM_STE_valid 0
#define ACM_STE_free  1

/* cache line:
 * if cache_line.valid==ACM_STE_valid, then
 *    STE decision is cached as "permitted" 
 *                 on domain cache_line.id
 */
struct acm_ste_cache_line {
    int valid; /* ACM_STE_* */
    domid_t id;
};

/* general definition of a subject security id */
struct acm_ssid_domain {
    struct list_head node; /* all are chained together */
    int datatype;          /* type of subject (e.g., partition): ACM_DATATYPE_* */
    ssidref_t ssidref;     /* combined security reference */
    ssidref_t old_ssidref; /* holds previous value of ssidref during relabeling */
    void *primary_ssid;    /* primary policy ssid part (e.g. chinese wall) */
    void *secondary_ssid;  /* secondary policy ssid part (e.g. type enforcement) */
    struct domain *subject;/* backpointer to subject structure */
    domid_t domainid;      /* replicate id */
};

/* chinese wall ssid type */
struct chwall_ssid {
    ssidref_t chwall_ssidref;
};

/* simple type enforcement ssid type */
struct ste_ssid {
    ssidref_t ste_ssidref;
    struct acm_ste_cache_line ste_cache[ACM_TE_CACHE_SIZE]; /* decision cache */
};

/* macros to access ssidref for primary / secondary policy 
 * primary ssidref   = lower 16 bit
 *  secondary ssidref = higher 16 bit
 */
#define ACM_PRIMARY(ssidref) \
 ((ssidref) & 0xffff)

#define ACM_SECONDARY(ssidref) \
 ((ssidref) >> 16)

#define GET_SSIDREF(POLICY, ssidref) \
 ((POLICY) == acm_bin_pol.primary_policy_code) ? \
 ACM_PRIMARY(ssidref) : ACM_SECONDARY(ssidref)

/* macros to access ssid pointer for primary / secondary policy */
#define GET_SSIDP(POLICY, ssid) \
 ((POLICY) == acm_bin_pol.primary_policy_code) ? \
 ((ssid)->primary_ssid) : ((ssid)->secondary_ssid)

#define ACM_INVALID_SSIDREF  (0xffffffff)

struct acm_sized_buffer
{
    uint32_t *array;
    uint num_items;
    uint position;
};

static inline int acm_array_append_tuple(struct acm_sized_buffer *buf,
                                         uint32_t a, uint32_t b)
{
    uint i;
    if (buf == NULL)
        return 0;

    i = buf->position;

    if ((i + 2) > buf->num_items)
        return 0;

    buf->array[i]   = cpu_to_be32(a);
    buf->array[i+1] = cpu_to_be32(b);
    buf->position += 2;
    return 1;
}

/* protos */
int acm_init_domain_ssid(struct domain *, ssidref_t ssidref);
void acm_free_domain_ssid(struct domain *);
int acm_init_binary_policy(u32 policy_code);
int acm_set_policy(XEN_GUEST_HANDLE_64(void) buf, u32 buf_size);
int do_acm_set_policy(void *buf, u32 buf_size, int is_bootpolicy,
                      struct acm_sized_buffer *, struct acm_sized_buffer *,
                      struct acm_sized_buffer *);
int acm_get_policy(XEN_GUEST_HANDLE_64(void) buf, u32 buf_size);
int acm_dump_statistics(XEN_GUEST_HANDLE_64(void) buf, u16 buf_size);
int acm_get_ssid(ssidref_t ssidref, XEN_GUEST_HANDLE_64(void) buf, u16 buf_size);
int acm_get_decision(ssidref_t ssidref1, ssidref_t ssidref2, u32 hook);
int acm_set_policy_reference(u8 * buf, u32 buf_size);
int acm_dump_policy_reference(u8 *buf, u32 buf_size);
int acm_change_policy(struct acm_change_policy *);
int acm_relabel_domains(struct acm_relabel_doms *);
int do_chwall_init_state_curr(struct acm_sized_buffer *);
int do_ste_init_state_curr(struct acm_sized_buffer *);

/* variables */
extern ssidref_t dom0_chwall_ssidref;
extern ssidref_t dom0_ste_ssidref;
#define ACM_MAX_NUM_TYPES   (256)

/* traversing the list of ssids */
extern struct list_head ssid_list;
#define for_each_acmssid( N )                               \
   for ( N =  (struct acm_ssid_domain *)ssid_list.next;     \
         N != (struct acm_ssid_domain *)&ssid_list;         \
         N =  (struct acm_ssid_domain *)N->node.next     )

#endif

/*
 * Local variables:
 * mode: C
 * c-set-style: "BSD"
 * c-basic-offset: 4
 * tab-width: 4
 * indent-tabs-mode: nil
 * End:
 */
