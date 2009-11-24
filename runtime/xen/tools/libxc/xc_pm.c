/******************************************************************************
 * xc_pm.c - Libxc API for Xen Power Management (Px/Cx/Tx, etc.) statistic
 *
 * Copyright (c) 2008, Liu Jinsong <jinsong.liu@intel.com>
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to
 * deal in the Software without restriction, including without limitation the
 * rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
 * sell copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 * DEALINGS IN THE SOFTWARE.
 *
 */

#include <errno.h>
#include <stdbool.h>
#include "xc_private.h"

/*
 * Get PM statistic info
 */
int xc_pm_get_max_px(int xc_handle, int cpuid, int *max_px)
{
    DECLARE_SYSCTL;
    int ret;

    sysctl.cmd = XEN_SYSCTL_get_pmstat;
    sysctl.u.get_pmstat.type = PMSTAT_get_max_px;
    sysctl.u.get_pmstat.cpuid = cpuid;
    ret = xc_sysctl(xc_handle, &sysctl);
    if ( ret )
        return ret;

    *max_px = sysctl.u.get_pmstat.u.getpx.total;
    return ret;
}

int xc_pm_get_pxstat(int xc_handle, int cpuid, struct xc_px_stat *pxpt)
{
    DECLARE_SYSCTL;
    int max_px, ret;

    if ( !pxpt || !(pxpt->trans_pt) || !(pxpt->pt) )
        return -EINVAL;

    if ( (ret = xc_pm_get_max_px(xc_handle, cpuid, &max_px)) != 0)
        return ret;

    if ( (ret = lock_pages(pxpt->trans_pt, 
        max_px * max_px * sizeof(uint64_t))) != 0 )
        return ret;

    if ( (ret = lock_pages(pxpt->pt, 
        max_px * sizeof(struct xc_px_val))) != 0 )
    {
        unlock_pages(pxpt->trans_pt, max_px * max_px * sizeof(uint64_t));
        return ret;
    }

    sysctl.cmd = XEN_SYSCTL_get_pmstat;
    sysctl.u.get_pmstat.type = PMSTAT_get_pxstat;
    sysctl.u.get_pmstat.cpuid = cpuid;
    sysctl.u.get_pmstat.u.getpx.total = max_px;
    set_xen_guest_handle(sysctl.u.get_pmstat.u.getpx.trans_pt, pxpt->trans_pt);
    set_xen_guest_handle(sysctl.u.get_pmstat.u.getpx.pt, 
                        (pm_px_val_t *)pxpt->pt);

    ret = xc_sysctl(xc_handle, &sysctl);
    if ( ret )
    {
        unlock_pages(pxpt->trans_pt, max_px * max_px * sizeof(uint64_t));
        unlock_pages(pxpt->pt, max_px * sizeof(struct xc_px_val));
        return ret;
    }

    pxpt->total = sysctl.u.get_pmstat.u.getpx.total;
    pxpt->usable = sysctl.u.get_pmstat.u.getpx.usable;
    pxpt->last = sysctl.u.get_pmstat.u.getpx.last;
    pxpt->cur = sysctl.u.get_pmstat.u.getpx.cur;

    unlock_pages(pxpt->trans_pt, max_px * max_px * sizeof(uint64_t));
    unlock_pages(pxpt->pt, max_px * sizeof(struct xc_px_val));

    return ret;
}

int xc_pm_reset_pxstat(int xc_handle, int cpuid)
{
    DECLARE_SYSCTL;

    sysctl.cmd = XEN_SYSCTL_get_pmstat;
    sysctl.u.get_pmstat.type = PMSTAT_reset_pxstat;
    sysctl.u.get_pmstat.cpuid = cpuid;

    return xc_sysctl(xc_handle, &sysctl);
}

int xc_pm_get_max_cx(int xc_handle, int cpuid, int *max_cx)
{
    DECLARE_SYSCTL;
    int ret = 0;

    sysctl.cmd = XEN_SYSCTL_get_pmstat;
    sysctl.u.get_pmstat.type = PMSTAT_get_max_cx;
    sysctl.u.get_pmstat.cpuid = cpuid;
    if ( (ret = xc_sysctl(xc_handle, &sysctl)) != 0 )
        return ret;

    *max_cx = sysctl.u.get_pmstat.u.getcx.nr;
    return ret;
}

int xc_pm_get_cxstat(int xc_handle, int cpuid, struct xc_cx_stat *cxpt)
{
    DECLARE_SYSCTL;
    int max_cx, ret;

    if( !cxpt || !(cxpt->triggers) || !(cxpt->residencies) )
        return -EINVAL;

    if ( (ret = xc_pm_get_max_cx(xc_handle, cpuid, &max_cx)) )
        goto unlock_0;

    if ( (ret = lock_pages(cxpt, sizeof(struct xc_cx_stat))) )
        goto unlock_0;
    if ( (ret = lock_pages(cxpt->triggers, max_cx * sizeof(uint64_t))) )
        goto unlock_1;
    if ( (ret = lock_pages(cxpt->residencies, max_cx * sizeof(uint64_t))) )
        goto unlock_2;

    sysctl.cmd = XEN_SYSCTL_get_pmstat;
    sysctl.u.get_pmstat.type = PMSTAT_get_cxstat;
    sysctl.u.get_pmstat.cpuid = cpuid;
    set_xen_guest_handle(sysctl.u.get_pmstat.u.getcx.triggers, cxpt->triggers);
    set_xen_guest_handle(sysctl.u.get_pmstat.u.getcx.residencies, 
                         cxpt->residencies);

    if ( (ret = xc_sysctl(xc_handle, &sysctl)) )
        goto unlock_3;

    cxpt->nr = sysctl.u.get_pmstat.u.getcx.nr;
    cxpt->last = sysctl.u.get_pmstat.u.getcx.last;
    cxpt->idle_time = sysctl.u.get_pmstat.u.getcx.idle_time;

unlock_3:
    unlock_pages(cxpt->residencies, max_cx * sizeof(uint64_t));
unlock_2:
    unlock_pages(cxpt->triggers, max_cx * sizeof(uint64_t));
unlock_1:
    unlock_pages(cxpt, sizeof(struct xc_cx_stat));
unlock_0:
    return ret;
}

int xc_pm_reset_cxstat(int xc_handle, int cpuid)
{
    DECLARE_SYSCTL;

    sysctl.cmd = XEN_SYSCTL_get_pmstat;
    sysctl.u.get_pmstat.type = PMSTAT_reset_cxstat;
    sysctl.u.get_pmstat.cpuid = cpuid;

    return xc_sysctl(xc_handle, &sysctl);
}


/*
 * 1. Get PM parameter
 * 2. Provide user PM control
 */
int xc_get_cpufreq_para(int xc_handle, int cpuid,
                        struct xc_get_cpufreq_para *user_para)
{
    DECLARE_SYSCTL;
    int ret = 0;
    struct xen_get_cpufreq_para *sys_para = &sysctl.u.pm_op.get_para;
    bool has_num = user_para->cpu_num &&
                     user_para->freq_num &&
                     user_para->gov_num;

    if ( (xc_handle < 0) || !user_para )
        return -EINVAL;

    if ( has_num )
    {
        if ( (!user_para->affected_cpus)                    ||
             (!user_para->scaling_available_frequencies)    ||
             (!user_para->scaling_available_governors) )
            return -EINVAL;

        if ( (ret = lock_pages(user_para->affected_cpus,
                               user_para->cpu_num * sizeof(uint32_t))) )
            goto unlock_1;
        if ( (ret = lock_pages(user_para->scaling_available_frequencies,
                               user_para->freq_num * sizeof(uint32_t))) )
            goto unlock_2;
        if ( (ret = lock_pages(user_para->scaling_available_governors,
                 user_para->gov_num * CPUFREQ_NAME_LEN * sizeof(char))) )
            goto unlock_3;

        set_xen_guest_handle(sys_para->affected_cpus,
                             user_para->affected_cpus);
        set_xen_guest_handle(sys_para->scaling_available_frequencies,
                             user_para->scaling_available_frequencies);
        set_xen_guest_handle(sys_para->scaling_available_governors,
                             user_para->scaling_available_governors);
    }

    sysctl.cmd = XEN_SYSCTL_pm_op;
    sysctl.u.pm_op.cmd = GET_CPUFREQ_PARA;
    sysctl.u.pm_op.cpuid = cpuid;
    sys_para->cpu_num  = user_para->cpu_num;
    sys_para->freq_num = user_para->freq_num;
    sys_para->gov_num  = user_para->gov_num;

    ret = xc_sysctl(xc_handle, &sysctl);
    if ( ret )
    {
        if ( errno == EAGAIN )
        {
            user_para->cpu_num  = sys_para->cpu_num;
            user_para->freq_num = sys_para->freq_num;
            user_para->gov_num  = sys_para->gov_num;
            ret = -errno;
        }

        if ( has_num )
            goto unlock_4;
        goto unlock_1;
    }
    else
    {
        user_para->cpuinfo_cur_freq = sys_para->cpuinfo_cur_freq;
        user_para->cpuinfo_max_freq = sys_para->cpuinfo_max_freq;
        user_para->cpuinfo_min_freq = sys_para->cpuinfo_min_freq;
        user_para->scaling_cur_freq = sys_para->scaling_cur_freq;
        user_para->scaling_max_freq = sys_para->scaling_max_freq;
        user_para->scaling_min_freq = sys_para->scaling_min_freq;

        memcpy(user_para->scaling_driver, 
                sys_para->scaling_driver, CPUFREQ_NAME_LEN);
        memcpy(user_para->scaling_governor,
                sys_para->scaling_governor, CPUFREQ_NAME_LEN);

        /* copy to user_para no matter what cpufreq governor */
        XC_BUILD_BUG_ON(sizeof(((struct xc_get_cpufreq_para *)0)->u) !=
                        sizeof(((struct xen_get_cpufreq_para *)0)->u));

        memcpy(&user_para->u, &sys_para->u, sizeof(sys_para->u));
    }

unlock_4:
    unlock_pages(user_para->scaling_available_governors,
                 user_para->gov_num * CPUFREQ_NAME_LEN * sizeof(char));
unlock_3:
    unlock_pages(user_para->scaling_available_frequencies,
                 user_para->freq_num * sizeof(uint32_t));
unlock_2:
    unlock_pages(user_para->affected_cpus,
                 user_para->cpu_num * sizeof(uint32_t));
unlock_1:
    return ret;
}

int xc_set_cpufreq_gov(int xc_handle, int cpuid, char *govname)
{
    DECLARE_SYSCTL;
    char *scaling_governor = sysctl.u.pm_op.set_gov.scaling_governor;

    if ( (xc_handle < 0) || (!govname) )
        return -EINVAL;

    sysctl.cmd = XEN_SYSCTL_pm_op;
    sysctl.u.pm_op.cmd = SET_CPUFREQ_GOV;
    sysctl.u.pm_op.cpuid = cpuid;
    strncpy(scaling_governor, govname, CPUFREQ_NAME_LEN);
    scaling_governor[CPUFREQ_NAME_LEN - 1] = '\0';

    return xc_sysctl(xc_handle, &sysctl);
}

int xc_set_cpufreq_para(int xc_handle, int cpuid, 
                        int ctrl_type, int ctrl_value)
{
    DECLARE_SYSCTL;

    if ( xc_handle < 0 )
        return -EINVAL;

    sysctl.cmd = XEN_SYSCTL_pm_op;
    sysctl.u.pm_op.cmd = SET_CPUFREQ_PARA;
    sysctl.u.pm_op.cpuid = cpuid;
    sysctl.u.pm_op.set_para.ctrl_type = ctrl_type;
    sysctl.u.pm_op.set_para.ctrl_value = ctrl_value;

    return xc_sysctl(xc_handle, &sysctl);
}

int xc_get_cpufreq_avgfreq(int xc_handle, int cpuid, int *avg_freq)
{
    int ret = 0;
    DECLARE_SYSCTL;

    if ( (xc_handle < 0) || (!avg_freq) )
        return -EINVAL;

    sysctl.cmd = XEN_SYSCTL_pm_op;
    sysctl.u.pm_op.cmd = GET_CPUFREQ_AVGFREQ;
    sysctl.u.pm_op.cpuid = cpuid;
    ret = xc_sysctl(xc_handle, &sysctl);

    *avg_freq = sysctl.u.pm_op.get_avgfreq;

    return ret;
}

int xc_get_cputopo(int xc_handle, struct xc_get_cputopo *info)
{
    int rc;
    DECLARE_SYSCTL;

    sysctl.cmd = XEN_SYSCTL_pm_op;
    sysctl.u.pm_op.cmd = XEN_SYSCTL_pm_op_get_cputopo;
    sysctl.u.pm_op.cpuid = 0;
    set_xen_guest_handle( sysctl.u.pm_op.get_topo.cpu_to_core,
                         info->cpu_to_core );
    set_xen_guest_handle( sysctl.u.pm_op.get_topo.cpu_to_socket,
                         info->cpu_to_socket );
    sysctl.u.pm_op.get_topo.max_cpus = info->max_cpus;

    rc = do_sysctl(xc_handle, &sysctl);
    info->nr_cpus = sysctl.u.pm_op.get_topo.nr_cpus;

    return rc;
}

/* value:   0 - disable sched_smt_power_savings 
            1 - enable sched_smt_power_savings
 */
int xc_set_sched_opt_smt(int xc_handle, uint32_t value)
{
   int rc;
   DECLARE_SYSCTL;

   sysctl.cmd = XEN_SYSCTL_pm_op;
   sysctl.u.pm_op.cmd = XEN_SYSCTL_pm_op_set_sched_opt_smt;
   sysctl.u.pm_op.cpuid = 0;
   sysctl.u.pm_op.set_sched_opt_smt = value;
   rc = do_sysctl(xc_handle, &sysctl);

   return rc;
}

int xc_set_vcpu_migration_delay(int xc_handle, uint32_t value)
{
   int rc;
   DECLARE_SYSCTL;

   sysctl.cmd = XEN_SYSCTL_pm_op;
   sysctl.u.pm_op.cmd = XEN_SYSCTL_pm_op_set_vcpu_migration_delay;
   sysctl.u.pm_op.cpuid = 0;
   sysctl.u.pm_op.set_vcpu_migration_delay = value;
   rc = do_sysctl(xc_handle, &sysctl);

   return rc;
}

int xc_get_vcpu_migration_delay(int xc_handle, uint32_t *value)
{
   int rc;
   DECLARE_SYSCTL;

   sysctl.cmd = XEN_SYSCTL_pm_op;
   sysctl.u.pm_op.cmd = XEN_SYSCTL_pm_op_get_vcpu_migration_delay;
   sysctl.u.pm_op.cpuid = 0;
   rc = do_sysctl(xc_handle, &sysctl);

   if (!rc && value)
       *value = sysctl.u.pm_op.get_vcpu_migration_delay;

   return rc;
}

int xc_get_cpuidle_max_cstate(int xc_handle, uint32_t *value)
{
    int rc;
    DECLARE_SYSCTL;

    if ( xc_handle < 0 || !value )
        return -EINVAL;

    sysctl.cmd = XEN_SYSCTL_pm_op;
    sysctl.u.pm_op.cmd = XEN_SYSCTL_pm_op_get_max_cstate;
    sysctl.u.pm_op.cpuid = 0;
    sysctl.u.pm_op.get_max_cstate = 0;
    rc = do_sysctl(xc_handle, &sysctl);
    *value = sysctl.u.pm_op.get_max_cstate;

    return rc;
}

int xc_set_cpuidle_max_cstate(int xc_handle, uint32_t value)
{
    DECLARE_SYSCTL;

    if ( xc_handle < 0 )
        return -EINVAL;

    sysctl.cmd = XEN_SYSCTL_pm_op;
    sysctl.u.pm_op.cmd = XEN_SYSCTL_pm_op_set_max_cstate;
    sysctl.u.pm_op.cpuid = 0;
    sysctl.u.pm_op.set_max_cstate = value;

    return do_sysctl(xc_handle, &sysctl);
}

