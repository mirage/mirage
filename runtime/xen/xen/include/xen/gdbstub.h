/*
 * Copyright (C) 2005 Hollis Blanchard <hollisb@us.ibm.com>, IBM Corporation
 * Copyright (C) 2006 Isaku Yamahata <yamahata at valinux co jp>
 *                    VA Linux Systems Japan. K.K.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307 USA
 */

#ifndef __XEN_GDBSTUB_H__
#define __XEN_GDBSTUB_H__

#include <asm/atomic.h>
#include <asm/page.h>

#ifdef CRASH_DEBUG

struct gdb_context {
    int                 serhnd;           /* handle on our serial line */
    int                 console_steal_id; /* handle on stolen console */
    bool_t              currently_attached;
    atomic_t            running;
    unsigned long       connected;
    u8                  signum;

    char                in_buf[PAGE_SIZE];
    unsigned long       in_bytes;

    char                out_buf[PAGE_SIZE];
    unsigned long       out_offset;
    u8                  out_csum;
};

/* interface to arch specific routines */
void gdb_write_to_packet(
    const char *buf, int count, struct gdb_context *ctx);
void gdb_write_to_packet_hex(
    unsigned long x, int int_size, struct gdb_context *ctx);
    /* ... writes in target native byte order as required by gdb spec. */
void gdb_send_packet(struct gdb_context *ctx);
void gdb_send_reply(const char *buf, struct gdb_context *ctx);

/* gdb stub trap handler: entry point */
int __trap_to_gdb(struct cpu_user_regs *regs, unsigned long cookie);

/* arch specific routines */
u16 gdb_arch_signal_num(
    struct cpu_user_regs *regs, unsigned long cookie);
void gdb_arch_read_reg_array(
    struct cpu_user_regs *regs, struct gdb_context *ctx);
void gdb_arch_write_reg_array(
    struct cpu_user_regs *regs, const char* buf, struct gdb_context *ctx);
void gdb_arch_read_reg(
    unsigned long regnum, struct cpu_user_regs *regs, struct gdb_context *ctx);
void gdb_arch_write_reg(
    unsigned long regnum, unsigned long val, struct cpu_user_regs *regs, 
    struct gdb_context *ctx);
unsigned int gdb_arch_copy_from_user(
    void *dest, const void *src, unsigned len);
unsigned int gdb_arch_copy_to_user(
    void *dest, const void *src, unsigned len);
void gdb_arch_resume(
    struct cpu_user_regs *regs, unsigned long addr,
    unsigned long type, struct gdb_context *ctx);
void gdb_arch_print_state(struct cpu_user_regs *regs);
void gdb_arch_enter(struct cpu_user_regs *regs);
void gdb_arch_exit(struct cpu_user_regs *regs);

#define GDB_CONTINUE     0
#define GDB_STEP         1

#define SIGILL           4
#define SIGTRAP          5
#define SIGBUS           7
#define SIGFPE           8
#define SIGSEGV         11
#define SIGALRM         14
#define SIGTERM         15

void initialise_gdb(void);

#else

#define initialise_gdb() ((void)0)

#endif

#endif /* __XEN_GDBSTUB_H__ */

/*
 * Local variables:
 * mode: C
 * c-set-style: "BSD"
 * c-basic-offset: 4
 * tab-width: 4
 * End:
 */
