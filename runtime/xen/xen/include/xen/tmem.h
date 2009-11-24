/******************************************************************************
 * tmem.h
 *
 * Transcendent memory
 *
 * Copyright (c) 2008, Dan Magenheimer, Oracle Corp.
 */

#ifndef __XEN_TMEM_H__
#define __XEN_TMEM_H__

extern void init_tmem(void);
extern void tmem_destroy(void *);
extern void *tmem_relinquish_pages(unsigned int, unsigned int);

#endif /* __XEN_TMEM_H__ */
