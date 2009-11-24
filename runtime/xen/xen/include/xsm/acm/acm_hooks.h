/****************************************************************
 * acm_hooks.h 
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
 * acm header file implementing the global (policy-independent)
 *      sHype hooks that are called throughout Xen.
 * 
 */

#ifndef _ACM_HOOKS_H
#define _ACM_HOOKS_H

#include <xen/config.h>
#include <xen/errno.h>
#include <xen/types.h>
#include <xen/lib.h>
#include <xen/delay.h>
#include <xen/sched.h>
#include <xen/multiboot.h>
#include <public/xsm/acm.h>
#include <xsm/acm/acm_core.h>
#include <public/domctl.h>
#include <public/event_channel.h>
#include <asm/current.h>

/*
 * HOOK structure and meaning (justifies a few words about our model):
 * 
 * General idea: every policy-controlled system operation is reflected in a 
 *               transaction in the system's security state
 *
 *      Keeping the security state consistent requires "atomic" transactions.
 *      The name of the hooks to place around policy-controlled transactions
 *      reflects this. If authorizations do not involve security state changes,
 *      then and only then POST and FAIL hooks remain empty since we don't care
 *      about the eventual outcome of the operation from a security viewpoint.
 *
 *      PURPOSE of hook types:
 *      ======================
 *      PRE-Hooks
 *       a) general authorization to guard a controlled system operation
 *       b) prepare security state change
 *          (means: fail hook must be able to "undo" this)
 *
 *      POST-Hooks
 *       a) commit prepared state change
 *
 *      FAIL-Hooks
 *       a) roll-back prepared security state change from PRE-Hook
 *
 *
 *      PLACEMENT of hook types:
 *      ========================
 *      PRE-Hooks must be called before a guarded/controlled system operation
 *      is started. They return ACM_ACCESS_PERMITTED, ACM_ACCESS_DENIED or
 *      error. Operation must be aborted if return is not ACM_ACCESS_PERMITTED.
 *
 *      POST-Hooks must be called after a successful system operation.
 *      There is no return value: commit never fails.
 *
 *      FAIL-Hooks must be called:
 *       a) if system transaction (operation) fails after calling the PRE-hook
 *       b) if another (secondary) policy denies access in its PRE-Hook
 *          (policy layering is useful but requires additional handling)
 *
 * Hook model from a security transaction viewpoint:
 *   start-sys-ops--> prepare ----succeed-----> commit --> sys-ops success
 *                   (pre-hook)  \           (post-hook)
 *                                \
 *                               fail
 *                                   \
 *                                    \
 *                                  roll-back
 *                                 (fail-hook)
 *                                        \
 *                                       sys-ops error
 *
 */

struct acm_operations {
    /* policy management functions (must always be defined!) */
    int  (*init_domain_ssid)           (void **ssid, ssidref_t ssidref);
    void (*free_domain_ssid)           (void *ssid);
    int  (*dump_binary_policy)         (u8 *buffer, u32 buf_size);
    int  (*test_binary_policy)         (u8 *buffer, u32 buf_size,
                                        int is_bootpolicy,
                                        struct acm_sized_buffer *);
    int  (*set_binary_policy)          (u8 *buffer, u32 buf_size);
    int  (*dump_statistics)            (u8 *buffer, u16 buf_size);
    int  (*dump_ssid_types)            (ssidref_t ssidref, u8 *buffer, u16 buf_size);
    /* domain management control hooks (can be NULL) */
    int  (*domain_create)              (void *subject_ssid, ssidref_t ssidref,
                                        domid_t domid);
    void (*domain_destroy)             (void *object_ssid, struct domain *d);
    /* event channel control hooks  (can be NULL) */
    int  (*pre_eventchannel_unbound)      (domid_t id1, domid_t id2);
    void (*fail_eventchannel_unbound)     (domid_t id1, domid_t id2);
    int  (*pre_eventchannel_interdomain)  (domid_t id);
    void (*fail_eventchannel_interdomain) (domid_t id);
    /* grant table control hooks (can be NULL)  */
    int  (*pre_grant_map_ref)          (domid_t id);
    void (*fail_grant_map_ref)         (domid_t id);
    int  (*pre_grant_setup)            (domid_t id);
    void (*fail_grant_setup)           (domid_t id);
    /* generic domain-requested decision hooks (can be NULL) */
    int (*sharing)                     (ssidref_t ssidref1,
                                        ssidref_t ssidref2);
    int (*authorization)               (ssidref_t ssidref1,
                                        ssidref_t ssidref2);
    int (*conflictset)                 (ssidref_t ssidref1);
    /* determine whether the default policy is installed */
    int (*is_default_policy)           (void);
};

/* global variables */
extern struct acm_operations *acm_primary_ops;
extern struct acm_operations *acm_secondary_ops;

/* if ACM_TRACE_MODE defined, all hooks should
 * print a short trace message */
/* #define ACM_TRACE_MODE */

#ifdef ACM_TRACE_MODE
# define traceprintk(fmt, args...) printk(fmt, ## args)
#else
# define traceprintk(fmt, args...)
#endif

/* if ACM_DEBUG defined, all hooks should
 * print a short trace message (comment it out
 * when not in testing mode )
 */
/* #define ACM_DEBUG */

#ifdef ACM_DEBUG
#  define printkd(fmt, args...) printk(fmt, ## args)
#else
#  define printkd(fmt, args...)
#endif

#ifndef ACM_SECURITY

static inline int acm_pre_eventchannel_unbound(domid_t id1, domid_t id2)
{ return 0; }
static inline int acm_pre_eventchannel_interdomain(domid_t id)
{ return 0; }
static inline int acm_pre_grant_map_ref(domid_t id) 
{ return 0; }
static inline int acm_pre_grant_setup(domid_t id) 
{ return 0; }
static inline int acm_is_policy(char *buf, unsigned long len)
{ return 0; }
static inline int acm_sharing(ssidref_t ssidref1, ssidref_t ssidref2)
{ return 0; }
static inline int acm_authorization(ssidref_t ssidref1, ssidref_t ssidref2)
{ return 0; }
static inline int acm_conflictset(ssidref_t ssidref1)
{ return 0; }
static inline int acm_domain_create(struct domain *d, ssidref_t ssidref)
{ return 0; }
static inline void acm_domain_destroy(struct domain *d)
{ return; }

#define DOM0_SSIDREF 0x0

#else

static inline void acm_domain_ssid_onto_list(struct acm_ssid_domain *ssid)
{
    write_lock(&ssid_list_rwlock);
    list_add(&ssid->node, &ssid_list);
    write_unlock(&ssid_list_rwlock);
}

static inline void acm_domain_ssid_off_list(struct acm_ssid_domain *ssid)
{
    write_lock(&ssid_list_rwlock);
    list_del(&ssid->node);
    write_unlock(&ssid_list_rwlock);
}

static inline int acm_pre_eventchannel_unbound(domid_t id1, domid_t id2)
{
    if ((acm_primary_ops->pre_eventchannel_unbound != NULL) && 
        acm_primary_ops->pre_eventchannel_unbound(id1, id2))
        return ACM_ACCESS_DENIED;
    else if ((acm_secondary_ops->pre_eventchannel_unbound != NULL) && 
             acm_secondary_ops->pre_eventchannel_unbound(id1, id2)) {
        /* roll-back primary */
        if (acm_primary_ops->fail_eventchannel_unbound != NULL)
            acm_primary_ops->fail_eventchannel_unbound(id1, id2);
        return ACM_ACCESS_DENIED;
    } else
        return ACM_ACCESS_PERMITTED;
}

static inline int acm_pre_eventchannel_interdomain(domid_t id)
{
    if ((acm_primary_ops->pre_eventchannel_interdomain != NULL) &&
        acm_primary_ops->pre_eventchannel_interdomain(id))
        return ACM_ACCESS_DENIED;
    else if ((acm_secondary_ops->pre_eventchannel_interdomain != NULL) &&
             acm_secondary_ops->pre_eventchannel_interdomain(id)) {
        /* roll-back primary */
        if (acm_primary_ops->fail_eventchannel_interdomain != NULL)
            acm_primary_ops->fail_eventchannel_interdomain(id);
        return ACM_ACCESS_DENIED;
    } else
        return ACM_ACCESS_PERMITTED;
}


static inline int acm_pre_grant_map_ref(domid_t id)
{
    if ( (acm_primary_ops->pre_grant_map_ref != NULL) &&
         acm_primary_ops->pre_grant_map_ref(id) )
    {
        return ACM_ACCESS_DENIED;
    }
    else if ( (acm_secondary_ops->pre_grant_map_ref != NULL) &&
              acm_secondary_ops->pre_grant_map_ref(id) )
    {
        /* roll-back primary */
        if ( acm_primary_ops->fail_grant_map_ref != NULL )
            acm_primary_ops->fail_grant_map_ref(id);
        return ACM_ACCESS_DENIED;
    }
    else
    {
        return ACM_ACCESS_PERMITTED;
    }
}

static inline int acm_pre_grant_setup(domid_t id)
{
    if ( (acm_primary_ops->pre_grant_setup != NULL) &&
         acm_primary_ops->pre_grant_setup(id) )
    {
        return ACM_ACCESS_DENIED;
    }
    else if ( (acm_secondary_ops->pre_grant_setup != NULL) &&
              acm_secondary_ops->pre_grant_setup(id) )
    {
        /* roll-back primary */
        if (acm_primary_ops->fail_grant_setup != NULL)
            acm_primary_ops->fail_grant_setup(id);
        return ACM_ACCESS_DENIED;
    }
    else
    {
        return ACM_ACCESS_PERMITTED;
    }
}


static inline void acm_domain_destroy(struct domain *d)
{
    void *ssid = d->ssid;
    if (ssid != NULL) {
        if (acm_primary_ops->domain_destroy != NULL)
            acm_primary_ops->domain_destroy(ssid, d);
        if (acm_secondary_ops->domain_destroy != NULL)
            acm_secondary_ops->domain_destroy(ssid, d);
        /* free security ssid for the destroyed domain (also if null policy */
        acm_domain_ssid_off_list(ssid);
        acm_free_domain_ssid(d);
    }
}


static inline int acm_domain_create(struct domain *d, ssidref_t ssidref)
{
    void *subject_ssid = current->domain->ssid;
    domid_t domid = d->domain_id;
    int rc;

    read_lock(&acm_bin_pol_rwlock);
    /*
       To be called when a domain is created; returns '0' if the
       domain is allowed to be created, != '0' if not.
     */
    rc = acm_init_domain_ssid(d, ssidref);
    if (rc != ACM_OK)
        goto error_out;

    if ((acm_primary_ops->domain_create != NULL) &&
        acm_primary_ops->domain_create(subject_ssid, ssidref, domid)) {
        rc = ACM_ACCESS_DENIED;
    } else if ((acm_secondary_ops->domain_create != NULL) &&
                acm_secondary_ops->domain_create(subject_ssid, ssidref,
                                                 domid)) {
        /* roll-back primary */
        if (acm_primary_ops->domain_destroy != NULL)
            acm_primary_ops->domain_destroy(d->ssid, d);
        rc = ACM_ACCESS_DENIED;
    }

    if ( rc == ACM_OK )
    {
        acm_domain_ssid_onto_list(d->ssid);
    } else {
        acm_free_domain_ssid(d);
    }

error_out:
    read_unlock(&acm_bin_pol_rwlock);
    return rc;
}


static inline int acm_sharing(ssidref_t ssidref1, ssidref_t ssidref2)
{
    if ((acm_primary_ops->sharing != NULL) &&
        acm_primary_ops->sharing(ssidref1, ssidref2))
        return ACM_ACCESS_DENIED;
    else if ((acm_secondary_ops->sharing != NULL) &&
             acm_secondary_ops->sharing(ssidref1, ssidref2)) {
        return ACM_ACCESS_DENIED;
    } else
        return ACM_ACCESS_PERMITTED;
}


static inline int acm_authorization(ssidref_t ssidref1, ssidref_t ssidref2)
{
    if ((acm_primary_ops->authorization != NULL) &&
        acm_primary_ops->authorization(ssidref1, ssidref2))
        return ACM_ACCESS_DENIED;
    else if ((acm_secondary_ops->authorization != NULL) &&
             acm_secondary_ops->authorization(ssidref1, ssidref2)) {
        return ACM_ACCESS_DENIED;
    } else
        return acm_sharing(ssidref1, ssidref2);
}


static inline int acm_conflictset(ssidref_t ssidref1)
{
    if ((acm_primary_ops->conflictset != NULL) &&
        acm_primary_ops->conflictset(ssidref1))
        return ACM_ACCESS_DENIED;
    else if ((acm_secondary_ops->conflictset != NULL) &&
             acm_secondary_ops->conflictset(ssidref1))
        return ACM_ACCESS_DENIED;
    return ACM_ACCESS_PERMITTED;
}

/* Return true iff buffer has an acm policy magic number.  */
extern int acm_is_policy(char *buf, unsigned long len);

#define DOM0_SSIDREF (dom0_ste_ssidref << 16 | dom0_chwall_ssidref)

#endif

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
