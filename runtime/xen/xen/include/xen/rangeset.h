/******************************************************************************
 * rangeset.h
 * 
 * Creation, maintenance and automatic destruction of per-domain sets of
 * numeric ranges.
 * 
 * Copyright (c) 2005, K A Fraser
 */

#ifndef __XEN_RANGESET_H__
#define __XEN_RANGESET_H__

struct domain;
struct rangeset;

/*
 * Initialise/destroy per-domain rangeset information.
 * 
 * It is invalid to create or destroy a rangeset belonging to a domain @d
 * before rangeset_domain_initialise(d) returns or after calling
 * rangeset_domain_destroy(d).
 */
void rangeset_domain_initialise(
    struct domain *d);
void rangeset_domain_destroy(
    struct domain *d);

/*
 * Create/destroy a rangeset. Optionally attach to specified domain @d for
 * auto-destruction when the domain dies. A name may be specified, for use
 * in debug pretty-printing, and various RANGESETF flags (defined below).
 * 
 * It is invalid to perform any operation on a rangeset @r after calling
 * rangeset_destroy(r).
 */
struct rangeset *rangeset_new(
    struct domain *d, char *name, unsigned int flags);
void rangeset_destroy(
    struct rangeset *r);

/* Flags for passing to rangeset_new(). */
 /* Pretty-print range limits in hexadecimal. */
#define _RANGESETF_prettyprint_hex 0
#define RANGESETF_prettyprint_hex  (1U << _RANGESETF_prettyprint_hex)

int __must_check rangeset_is_empty(
    struct rangeset *r);

/* Add/remove/query a numeric range. */
int __must_check rangeset_add_range(
    struct rangeset *r, unsigned long s, unsigned long e);
int __must_check rangeset_remove_range(
    struct rangeset *r, unsigned long s, unsigned long e);
int __must_check rangeset_contains_range(
    struct rangeset *r, unsigned long s, unsigned long e);
int rangeset_report_ranges(
    struct rangeset *r, unsigned long s, unsigned long e,
    int (*cb)(unsigned long s, unsigned long e, void *), void *ctxt);

/* Add/remove/query a single number. */
int __must_check rangeset_add_singleton(
    struct rangeset *r, unsigned long s);
int __must_check rangeset_remove_singleton(
    struct rangeset *r, unsigned long s);
int __must_check rangeset_contains_singleton(
    struct rangeset *r, unsigned long s);

/* Rangeset pretty printing. */
void rangeset_printk(
    struct rangeset *r);
void rangeset_domain_printk(
    struct domain *d);

#endif /* __XEN_RANGESET_H__ */
