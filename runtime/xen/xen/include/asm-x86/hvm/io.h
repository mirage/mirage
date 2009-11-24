/*
 * io.h: HVM IO support
 *
 * Copyright (c) 2004, Intel Corporation.
 *
 * This program is free software; you can redistribute it and/or modify it
 * under the terms and conditions of the GNU General Public License,
 * version 2, as published by the Free Software Foundation.
 *
 * This program is distributed in the hope it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
 * more details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program; if not, write to the Free Software Foundation, Inc., 59 Temple
 * Place - Suite 330, Boston, MA 02111-1307 USA.
 */

#ifndef __ASM_X86_HVM_IO_H__
#define __ASM_X86_HVM_IO_H__

#include <asm/hvm/vpic.h>
#include <asm/hvm/vioapic.h>
#include <public/hvm/ioreq.h>
#include <public/event_channel.h>

#define MAX_IO_HANDLER             16

#define HVM_PORTIO                  0
#define HVM_BUFFERED_IO             2

typedef int (*hvm_mmio_read_t)(struct vcpu *v,
                               unsigned long addr,
                               unsigned long length,
                               unsigned long *val);
typedef int (*hvm_mmio_write_t)(struct vcpu *v,
                                unsigned long addr,
                                unsigned long length,
                                unsigned long val);
typedef int (*hvm_mmio_check_t)(struct vcpu *v, unsigned long addr);

typedef int (*portio_action_t)(
    int dir, uint32_t port, uint32_t bytes, uint32_t *val);
typedef int (*mmio_action_t)(ioreq_t *);
struct io_handler {
    int                 type;
    unsigned long       addr;
    unsigned long       size;
    union {
        portio_action_t portio;
        mmio_action_t   mmio;
    } action;
};

struct hvm_io_handler {
    int     num_slot;
    struct  io_handler hdl_list[MAX_IO_HANDLER];
};

struct hvm_mmio_handler {
    hvm_mmio_check_t check_handler;
    hvm_mmio_read_t read_handler;
    hvm_mmio_write_t write_handler;
};

int hvm_io_intercept(ioreq_t *p, int type);
void register_io_handler(
    struct domain *d, unsigned long addr, unsigned long size,
    void *action, int type);

static inline int hvm_portio_intercept(ioreq_t *p)
{
    return hvm_io_intercept(p, HVM_PORTIO);
}

static inline int hvm_buffered_io_intercept(ioreq_t *p)
{
    return hvm_io_intercept(p, HVM_BUFFERED_IO);
}

int hvm_mmio_intercept(ioreq_t *p);
int hvm_buffered_io_send(ioreq_t *p);

static inline void register_portio_handler(
    struct domain *d, unsigned long addr,
    unsigned long size, portio_action_t action)
{
    register_io_handler(d, addr, size, action, HVM_PORTIO);
}

static inline void register_buffered_io_handler(
    struct domain *d, unsigned long addr,
    unsigned long size, mmio_action_t action)
{
    register_io_handler(d, addr, size, action, HVM_BUFFERED_IO);
}

void send_timeoffset_req(unsigned long timeoff);
void send_invalidate_req(void);
int handle_mmio(void);
int handle_mmio_with_translation(unsigned long gva, unsigned long gpfn);
void hvm_interrupt_post(struct vcpu *v, int vector, int type);
void hvm_io_assist(void);
void hvm_dpci_eoi(struct domain *d, unsigned int guest_irq,
                  union vioapic_redir_entry *ent);

struct hvm_hw_stdvga {
    uint8_t sr_index;
    uint8_t sr[8];
    uint8_t gr_index;
    uint8_t gr[9];
    bool_t stdvga;
    bool_t cache;
    uint32_t latch;
    struct page_info *vram_page[64];  /* shadow of 0xa0000-0xaffff */
    spinlock_t lock;
};

void stdvga_init(struct domain *d);
void stdvga_deinit(struct domain *d);

extern void hvm_dpci_msi_eoi(struct domain *d, int vector);
#endif /* __ASM_X86_HVM_IO_H__ */

