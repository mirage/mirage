/******************************************************************************
 * xen/console.h
 * 
 * Xen header file concerning console access.
 */

#ifndef __CONSOLE_H__
#define __CONSOLE_H__

#include <xen/spinlock.h>
#include <xen/guest_access.h>
#include <public/xen.h>

struct xen_sysctl_readconsole;
long read_console_ring(struct xen_sysctl_readconsole *op);

void console_init_preirq(void);
void console_init_postirq(void);
void console_endboot(void);
int console_has(const char *device);

int fill_console_start_info(struct dom0_vga_console_info *);

void console_force_unlock(void);
void console_force_lock(void);

void console_start_sync(void);
void console_end_sync(void);

void console_start_log_everything(void);
void console_end_log_everything(void);

/*
 * Steal output from the console. Returns +ve identifier, else -ve error.
 * Takes the handle of the serial line to steal, and steal callback function.
 */
int console_steal(int handle, void (*fn)(const char *));

/* Give back stolen console. Takes the identifier returned by console_steal. */
void console_giveback(int id);

int console_suspend(void);
int console_resume(void);

#endif /* __CONSOLE_H__ */
