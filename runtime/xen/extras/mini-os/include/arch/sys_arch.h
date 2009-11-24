/* 
 * lwip/arch/sys_arch.h
 *
 * Arch-specific semaphores and mailboxes for lwIP running on mini-os 
 *
 * Tim Deegan <Tim.Deegan@eu.citrix.net>, July 2007
 */

#ifndef __LWIP_ARCH_SYS_ARCH_H__
#define __LWIP_ARCH_SYS_ARCH_H__

#include <mini-os/os.h>
#include <mini-os/xmalloc.h>
#include <mini-os/semaphore.h>

typedef struct semaphore *sys_sem_t;
#define SYS_SEM_NULL ((sys_sem_t) NULL)

struct mbox {
    int count;
    void **messages;
    struct semaphore read_sem;
    struct semaphore write_sem;
    int writer;
    int reader;
};

typedef struct mbox *sys_mbox_t;
#define SYS_MBOX_NULL ((sys_mbox_t) 0)

typedef struct thread *sys_thread_t;

typedef unsigned long sys_prot_t;

#endif /*__LWIP_ARCH_SYS_ARCH_H__ */
