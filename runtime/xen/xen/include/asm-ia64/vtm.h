
/* -*-  Mode:C; c-basic-offset:4; tab-width:4; indent-tabs-mode:nil -*- */
/*
 * vtm.h: virtual timer head file.
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
 *
 *  Yaozu Dong (Eddie Dong) (Eddie.dong@intel.com)
 */

#ifndef _VTM_H_
#define _VTM_H_

#include <xen/timer.h>
#include <xen/types.h>

#define MAX_JUMP_STEP       (5000)   /* 500ms, max jump step */
#define MIN_GUEST_RUNNING_TIME  (0)    /* 10ms for guest os to run */
#define ITV_VECTOR_MASK     (0xff)

typedef struct vtime {
    	long        vtm_offset; // guest ITC = host ITC + vtm_offset
    	uint64_t    vtm_local_drift;
	uint64_t    last_itc;
    	uint64_t    pending;
    	/* 
    	 * Local drift (temporary) after guest suspension
    	 * In case of long jump amount of ITC after suspension, 
    	 * guest ITC = host ITC + vtm_offset - vtm_local_drift;
    	 * so that the duration passed saw in guest ITC is limited to 
    	 * cfg_max_jump that will make all kind of device driver happy.
    	 */

    	// next all uses ITC tick as unit   
    	uint64_t    cfg_max_jump;   // max jump within one time suspendsion
    	uint64_t    cfg_min_grun;   // min guest running time since last jump
//    	uint64_t    latest_read_itc;    // latest guest read ITC
    	struct timer	vtm_timer;
//	int        triggered;
    	

    	uint64_t    guest_running_time; // guest running time since last switch
    	//uint64_t  vtm_last_suspending_time;
    	//uint64_t    switch_in_time;
    	//uint64_t    switch_out_time;
	//uint64_t    itc_freq;
    	
} vtime_t;

#define  ITV_VECTOR(itv)    (itv&0xff)
#define  ITV_IRQ_MASK(itv)  (itv&(1<<16))

#define	 VTM_FIRED(vtm)     	((vtm)->triggered)

#endif /* _STATS_H_ */
