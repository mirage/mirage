/*
 * cpuidle.h - xen idle state module derived from Linux 
 *
 * (C) 2007 Venkatesh Pallipadi <venkatesh.pallipadi@intel.com>
 *          Shaohua Li <shaohua.li@intel.com>
 *          Adam Belay <abelay@novell.com>
 *  Copyright (C) 2008 Intel Corporation
 *
 * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or (at
 *  your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful, but
 *  WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 *  General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License along
 *  with this program; if not, write to the Free Software Foundation, Inc.,
 *  59 Temple Place, Suite 330, Boston, MA 02111-1307 USA.
 *
 * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 */
#ifndef _XEN_CPUIDLE_H
#define _XEN_CPUIDLE_H

#define ACPI_PROCESSOR_MAX_POWER        8
#define CPUIDLE_NAME_LEN                16

#define ACPI_CSTATE_EM_NONE     0
#define ACPI_CSTATE_EM_SYSIO    1
#define ACPI_CSTATE_EM_FFH      2
#define ACPI_CSTATE_EM_HALT     3

struct acpi_processor_cx
{
    u8 idx;
    u8 valid;
    u8 type;
    u32 address;
    u8 entry_method; /* ACPI_CSTATE_EM_xxx */
    u32 latency;
    u32 latency_ticks;
    u32 power;
    u32 usage;
    u64 time;
    u32 target_residency;
};

struct acpi_processor_flags
{
    u8 bm_control:1;
    u8 bm_check:1;
    u8 has_cst:1;
    u8 power_setup_done:1;
    u8 bm_rld_set:1;
};

struct acpi_processor_power
{
    unsigned int cpu;
    struct acpi_processor_flags flags;
    struct acpi_processor_cx *last_state;
    struct acpi_processor_cx *safe_state;
    u32 last_residency;
    void *gdata; /* governor specific data */
    u32 count;
    struct acpi_processor_cx states[ACPI_PROCESSOR_MAX_POWER];
};

struct cpuidle_governor
{
    char                    name[CPUIDLE_NAME_LEN];
    unsigned int            rating;

    int  (*enable)          (struct acpi_processor_power *dev);
    void (*disable)         (struct acpi_processor_power *dev);

    int  (*select)          (struct acpi_processor_power *dev);
    void (*reflect)         (struct acpi_processor_power *dev);
};

extern struct cpuidle_governor *cpuidle_current_governor;
void cpuidle_disable_deep_cstate(void);

#endif /* _XEN_CPUIDLE_H */
