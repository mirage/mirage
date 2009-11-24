/******************************************************************************
 * xc_cpu_hotplug.c - Libxc API for Xen Physical CPU hotplug Management
 *
 * Copyright (c) 2008, Shan Haitao <haitao.shan@intel.com>
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

#include "xc_private.h"

int xc_cpu_online(int xc_handle, int cpu)
{
    DECLARE_SYSCTL;
    int ret;

    sysctl.cmd = XEN_SYSCTL_cpu_hotplug;
    sysctl.u.cpu_hotplug.cpu = cpu;
    sysctl.u.cpu_hotplug.op = XEN_SYSCTL_CPU_HOTPLUG_ONLINE;
    ret = xc_sysctl(xc_handle, &sysctl);

    return ret;
}

int xc_cpu_offline(int xc_handle, int cpu)
{
    DECLARE_SYSCTL;
    int ret;

    sysctl.cmd = XEN_SYSCTL_cpu_hotplug;
    sysctl.u.cpu_hotplug.cpu = cpu;
    sysctl.u.cpu_hotplug.op = XEN_SYSCTL_CPU_HOTPLUG_OFFLINE;
    ret = xc_sysctl(xc_handle, &sysctl);

    return ret;
}

