#ifndef __XEN_SHUTDOWN_H__
#define __XEN_SHUTDOWN_H__

/* opt_noreboot: If true, machine will need manual reset on error. */
extern int opt_noreboot;

void dom0_shutdown(u8 reason);

void machine_restart(unsigned int delay_millisecs);
void machine_halt(void);
void machine_power_off(void);

#endif /* __XEN_SHUTDOWN_H__ */
