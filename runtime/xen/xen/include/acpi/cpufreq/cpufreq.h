/*
 *  xen/include/acpi/cpufreq/cpufreq.h
 *
 *  Copyright (C) 2001 Russell King
 *            (C) 2002 - 2003 Dominik Brodowski <linux@brodo.de>
 *
 * $Id: cpufreq.h,v 1.36 2003/01/20 17:31:48 db Exp $
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 2 as
 * published by the Free Software Foundation.
 */

#ifndef __XEN_CPUFREQ_PM_H__
#define __XEN_CPUFREQ_PM_H__

#include <xen/types.h>
#include <xen/list.h>
#include <xen/cpumask.h>

#include "processor_perf.h"

DECLARE_PER_CPU(spinlock_t, cpufreq_statistic_lock);

struct cpufreq_governor;

struct acpi_cpufreq_data {
    struct processor_performance *acpi_data;
    struct cpufreq_frequency_table *freq_table;
    unsigned int max_freq;
    unsigned int cpu_feature;
};

struct cpufreq_cpuinfo {
    unsigned int        max_freq;
    unsigned int        min_freq;
    unsigned int        transition_latency; /* in 10^(-9) s = nanoseconds */
};

struct cpufreq_policy {
    cpumask_t           cpus;          /* affected CPUs */
    unsigned int        shared_type;   /* ANY or ALL affected CPUs
                                          should set cpufreq */
    unsigned int        cpu;           /* cpu nr of registered CPU */
    struct cpufreq_cpuinfo    cpuinfo;

    unsigned int        min;    /* in kHz */
    unsigned int        max;    /* in kHz */
    unsigned int        cur;    /* in kHz, only needed if cpufreq
                                 * governors are used */
    struct cpufreq_governor     *governor;

    unsigned int        resume; /* flag for cpufreq 1st run
                                 * S3 wakeup, hotplug cpu, etc */
};
extern struct cpufreq_policy *cpufreq_cpu_policy[NR_CPUS];

extern int __cpufreq_set_policy(struct cpufreq_policy *data,
                                struct cpufreq_policy *policy);

void cpufreq_cmdline_parse(char *);

#define CPUFREQ_SHARED_TYPE_NONE (0) /* None */
#define CPUFREQ_SHARED_TYPE_HW   (1) /* HW does needed coordination */
#define CPUFREQ_SHARED_TYPE_ALL  (2) /* All dependent CPUs should set freq */
#define CPUFREQ_SHARED_TYPE_ANY  (3) /* Freq can be set from any dependent CPU*/

/******************** cpufreq transition notifiers *******************/

struct cpufreq_freqs {
    unsigned int cpu;    /* cpu nr */
    unsigned int old;
    unsigned int new;
    u8 flags;            /* flags of cpufreq_driver, see below. */
};


/*********************************************************************
 *                          CPUFREQ GOVERNORS                        *
 *********************************************************************/

#define CPUFREQ_GOV_START  1
#define CPUFREQ_GOV_STOP   2
#define CPUFREQ_GOV_LIMITS 3

struct cpufreq_governor {
    char    name[CPUFREQ_NAME_LEN];
    int     (*governor)(struct cpufreq_policy *policy,
                        unsigned int event);
    void    (*handle_option)(const char *name, const char *value);
    struct list_head governor_list;
};

extern struct cpufreq_governor *cpufreq_opt_governor;
extern struct cpufreq_governor cpufreq_gov_dbs;
extern struct cpufreq_governor cpufreq_gov_userspace;
extern struct cpufreq_governor cpufreq_gov_performance;
extern struct cpufreq_governor cpufreq_gov_powersave;

extern int cpufreq_register_governor(struct cpufreq_governor *governor);
extern int cpufreq_unregister_governor(struct cpufreq_governor *governor);
extern struct cpufreq_governor *__find_governor(const char *governor);
#define CPUFREQ_DEFAULT_GOVERNOR &cpufreq_gov_userspace

/* pass a target to the cpufreq driver */
extern int __cpufreq_driver_target(struct cpufreq_policy *policy,
                                   unsigned int target_freq,
                                   unsigned int relation);

#define GOV_GETAVG     1
#define USR_GETAVG     2
extern int cpufreq_driver_getavg(unsigned int cpu, unsigned int flag);

static __inline__ int 
__cpufreq_governor(struct cpufreq_policy *policy, unsigned int event)
{
    return policy->governor->governor(policy, event);
}


/*********************************************************************
 *                      CPUFREQ DRIVER INTERFACE                     *
 *********************************************************************/

#define CPUFREQ_RELATION_L 0  /* lowest frequency at or above target */
#define CPUFREQ_RELATION_H 1  /* highest frequency below or at target */

struct cpufreq_driver {
    char   name[CPUFREQ_NAME_LEN];
    int    (*init)(struct cpufreq_policy *policy);
    int    (*verify)(struct cpufreq_policy *policy);
    int    (*target)(struct cpufreq_policy *policy,
                     unsigned int target_freq,
                     unsigned int relation);
    unsigned int    (*get)(unsigned int cpu);
    unsigned int    (*getavg)(unsigned int cpu, unsigned int flag);
    int    (*exit)(struct cpufreq_policy *policy);
};

extern struct cpufreq_driver *cpufreq_driver;

static __inline__ 
int cpufreq_register_driver(struct cpufreq_driver *driver_data)
{
    if (!driver_data         || 
        !driver_data->init   || 
        !driver_data->exit   || 
        !driver_data->verify || 
        !driver_data->target)
        return -EINVAL;

    if (cpufreq_driver)
        return -EBUSY;

    cpufreq_driver = driver_data;
    return 0;
}

static __inline__ 
int cpufreq_unregister_driver(struct cpufreq_driver *driver)
{
    if (!cpufreq_driver || (driver != cpufreq_driver))
        return -EINVAL;

    cpufreq_driver = NULL;
    return 0;
}

static __inline__
void cpufreq_verify_within_limits(struct cpufreq_policy *policy,
                                  unsigned int min, unsigned int max)
{
    if (policy->min < min)
        policy->min = min;
    if (policy->max < min)
        policy->max = min;
    if (policy->min > max)
        policy->min = max;
    if (policy->max > max)
        policy->max = max;
    if (policy->min > policy->max)
        policy->min = policy->max;
    return;
}


/*********************************************************************
 *                     FREQUENCY TABLE HELPERS                       *
 *********************************************************************/

#define CPUFREQ_ENTRY_INVALID ~0
#define CPUFREQ_TABLE_END     ~1

struct cpufreq_frequency_table {
    unsigned int    index;     /* any */
    unsigned int    frequency; /* kHz - doesn't need to be in ascending
                                * order */
};

int cpufreq_frequency_table_cpuinfo(struct cpufreq_policy *policy,
                   struct cpufreq_frequency_table *table);

int cpufreq_frequency_table_verify(struct cpufreq_policy *policy,
                   struct cpufreq_frequency_table *table);

int cpufreq_frequency_table_target(struct cpufreq_policy *policy,
                   struct cpufreq_frequency_table *table,
                   unsigned int target_freq,
                   unsigned int relation,
                   unsigned int *index);


/*********************************************************************
 *                     UNIFIED DEBUG HELPERS                         *
 *********************************************************************/

struct cpu_dbs_info_s {
    uint64_t prev_cpu_idle;
    uint64_t prev_cpu_wall;
    struct cpufreq_policy *cur_policy;
    struct cpufreq_frequency_table *freq_table;
    int cpu;
    unsigned int enable:1;
    unsigned int stoppable:1;
};

int cpufreq_governor_dbs(struct cpufreq_policy *policy, unsigned int event);
int get_cpufreq_ondemand_para(uint32_t *sampling_rate_max,
                              uint32_t *sampling_rate_min,
                              uint32_t *sampling_rate,
                              uint32_t *up_threshold);
int write_ondemand_sampling_rate(unsigned int sampling_rate);
int write_ondemand_up_threshold(unsigned int up_threshold);

int write_userspace_scaling_setspeed(unsigned int cpu, unsigned int freq);

void cpufreq_dbs_timer_suspend(void);
void cpufreq_dbs_timer_resume(void);
#endif /* __XEN_CPUFREQ_PM_H__ */
