/* -*-  Mode:C; c-basic-offset:4; tab-width:4; indent-tabs-mode:nil -*- */
/*
 * Copyright (c) 2005, Intel Corporation.
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
 *  Xuefei Xu (Anthony Xu) (Anthony.xu@intel.com)
 */



#ifndef _PAL_VSA_H_
#define _PAL_VSA_H_

/* PAL virtualization services */

#ifndef __ASSEMBLY__
extern u64 ia64_call_vsa(u64 proc, u64 arg1, u64 arg2, u64 arg3,
                         u64 arg4, u64 arg5, u64 arg6, u64 arg7);

/* entry points in assembly code for calling vps services */

extern char vmx_vps_sync_read;
extern char vmx_vps_sync_write;
extern char vmx_vps_resume_normal;
extern char vmx_vps_resume_handler;

extern u64 __vsa_base;
#endif  /* __ASSEMBLY__ */

#define PAL_VPS_RESUME_NORMAL           0x0000
#define PAL_VPS_RESUME_HANDLER          0x0400
#define PAL_VPS_SYNC_READ           0x0800
#define PAL_VPS_SYNC_WRITE          0x0c00
#define PAL_VPS_SET_PENDING_INTERRUPT       0x1000
#define PAL_VPS_THASH               0x1400
#define PAL_VPS_TTAG                0x1800
#define PAL_VPS_RESTORE             0x1c00
#define PAL_VPS_SAVE                0x2000

#endif /* _PAL_VSA_H_ */

