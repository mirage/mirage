/*
 * vacpi.h: Virtual ACPI definitions
 *
 * Copyright (c) 2007, FUJITSU LIMITED
 *      Kouya Shimura <kouya at jp fujitsu com>
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

#ifndef __ASM_IA64_HVM_VACPI_H__
#define __ASM_IA64_HVM_VACPI_H__

#include <public/arch-ia64/hvm/save.h> /* for struct vacpi_regs */
#include <public/hvm/ioreq.h>

#define ACPI_PM1A_EVT_BLK_ADDRESS 0x0000000000001f40
#define ACPI_PM1A_CNT_BLK_ADDRESS (ACPI_PM1A_EVT_BLK_ADDRESS + 0x04)
#define ACPI_PM_TMR_BLK_ADDRESS   (ACPI_PM1A_EVT_BLK_ADDRESS + 0x08)

#define IS_ACPI_ADDR(X)  ((unsigned long)((X)-ACPI_PM1A_EVT_BLK_ADDRESS)<12)

#define FREQUENCE_PMTIMER  3579545UL	/* Timer should run at 3.579545 MHz */

struct vacpi {
	struct vacpi_regs regs;
	s_time_t last_gtime;
	struct timer timer;
	spinlock_t lock;
};

int vacpi_intercept(ioreq_t * p, u64 * val);
void vacpi_init(struct domain *d);
void vacpi_relinquish_resources(struct domain *d);

#endif	/* __ASM_IA64_HVM_VACPI_H__ */
