#ifndef _SYS_REBOOT_H
#define _SYS_REBOOT_H

#include <sys/cdefs.h>

__BEGIN_DECLS

#define	LINUX_REBOOT_MAGIC1	0xfee1dead
#define	LINUX_REBOOT_MAGIC2	672274793
#define	LINUX_REBOOT_MAGIC2A	85072278
#define	LINUX_REBOOT_MAGIC2B	369367448

#define	LINUX_REBOOT_CMD_RESTART	0x01234567
#define	LINUX_REBOOT_CMD_HALT		0xCDEF0123
#define	LINUX_REBOOT_CMD_CAD_ON		0x89ABCDEF
#define	LINUX_REBOOT_CMD_CAD_OFF	0x00000000
#define	LINUX_REBOOT_CMD_POWER_OFF	0x4321FEDC
#define	LINUX_REBOOT_CMD_RESTART2	0xA1B2C3D4

/* Reboot or halt the system.  */
int reboot (int flag);

/* the glibc people changed their macro names :-/ */
#define RB_AUTOBOOT	0x01234567
#define RB_HALT_SYSTEM	0xcdef0123
#define RB_ENABLE_CAD	0x89abcdef
#define RB_DISABLE_CAD	0
#define RB_POWER_OFF	0x4321fedc

__END_DECLS

#endif	/* _SYS_REBOOT_H */
