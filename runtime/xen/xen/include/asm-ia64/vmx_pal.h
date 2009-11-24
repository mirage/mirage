#ifndef _ASM_IA64_VT_PAL_H
#define _ASM_IA64_VT_PAL_H

/* -*-  Mode:C; c-basic-offset:4; tab-width:4; indent-tabs-mode:nil -*- */
/*
 * vmx_pal.h: VT-I specific PAL  (Processor Abstraction Layer) definitions
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
 *	Xuefei Xu (Anthony Xu) (anthony.xu@intel.com)
 *	Fred Yang (fred.yang@intel.com)
 * 	Kun Tian (Kevin Tian) (kevin.tian@intel.com)
 */

#include <xen/types.h>
/* PAL PROCEDURE FOR VIRTUALIZATION */
#define		PAL_VP_CREATE   265
/* Stacked Virt. Initializes a new VPD for the operation of
 * a new virtual processor in the virtual environment.
*/
#define		PAL_VP_ENV_INFO 266
/*Stacked Virt. Returns the parameters needed to enter a virtual environment.*/
#define		PAL_VP_EXIT_ENV 267
/*Stacked Virt. Allows a logical processor to exit a virtual environment.*/
#define		PAL_VP_INIT_ENV 268
/*Stacked Virt. Allows a logical processor to enter a virtual environment.*/
#define		PAL_VP_REGISTER 269
/*Stacked Virt. Register a different host IVT for the virtual processor.*/
#define		PAL_VP_RESUME   270
/* Renamed from PAL_VP_RESUME */
#define		PAL_VP_RESTORE  270
/*Stacked Virt. Resumes virtual processor operation on the logical processor.*/
#define		PAL_VP_SUSPEND  271
/* Renamed from PAL_VP_SUSPEND */
#define		PAL_VP_SAVE	271
/* Stacked Virt. Suspends operation for the specified virtual processor on
 * the logical processor.
 */
#define		PAL_VP_TERMINATE 272
/* Stacked Virt. Terminates operation for the specified virtual processor.*/

static inline s64
ia64_pal_vp_env_info(u64 *buffer_size, u64 *vp_env_info)
{
	struct ia64_pal_retval iprv;
	PAL_CALL_STK(iprv, PAL_VP_ENV_INFO, 0, 0, 0);
	*buffer_size=iprv.v0;
	*vp_env_info=iprv.v1;
	return iprv.status;
}

static inline s64
ia64_pal_vp_exit_env(u64 iva)
{
	struct ia64_pal_retval iprv;
	PAL_CALL_STK(iprv, PAL_VP_EXIT_ENV, (u64)iva, 0, 0);
	return iprv.status;
}

/* config_options in pal_vp_init_env */
#define	VP_INITIALIZE	1UL
#define	VP_FR_PMC	1UL<<1
#define	VP_OPCODE	1UL<<8
#define	VP_CAUSE	1UL<<9
#define	VP_FW_ACC	1UL<<63
/* init vp env with initializing vm_buffer */
#define	VP_INIT_ENV_INITALIZE  VP_INITIALIZE|VP_FR_PMC|VP_OPCODE|VP_CAUSE|VP_FW_ACC
/* init vp env without initializing vm_buffer */
#define	VP_INIT_ENV  VP_FR_PMC|VP_OPCODE|VP_CAUSE|VP_FW_ACC

static inline s64
ia64_pal_vp_init_env (u64 config_options, u64 pbase_addr, \
		u64 vbase_addr, u64 * vsa_base)
{
	struct ia64_pal_retval iprv;
	PAL_CALL_STK(iprv, PAL_VP_INIT_ENV, config_options, pbase_addr,\
		 vbase_addr);
	*vsa_base=iprv.v0;
	return iprv.status;
}

static inline s64
ia64_pal_vp_create (u64 *vpd, u64 *host_iva, u64* opt_handler)
{
	struct ia64_pal_retval iprv;
	PAL_CALL_STK(iprv, PAL_VP_CREATE, (u64)vpd, (u64)host_iva,
			(u64)opt_handler);
	return iprv.status;
}

static inline s64
ia64_pal_vp_restore (u64 *vpd, u64 pal_proc_vector)
{
	struct ia64_pal_retval iprv;
	PAL_CALL_STK(iprv, PAL_VP_RESTORE, (u64)vpd, pal_proc_vector, 0);
	return iprv.status;
}

static inline s64
ia64_pal_vp_save (u64 *vpd, u64 pal_proc_vector)
{
	struct ia64_pal_retval iprv;
	PAL_CALL_STK(iprv, PAL_VP_SAVE, (u64)vpd, pal_proc_vector, 0);
	return iprv.status;
}
extern void pal_emul(struct vcpu *vcpu);
extern void sal_emul(struct vcpu *vcpu);
#define PAL_PROC_VM_BIT		(1UL << 40)
#define PAL_PROC_VMSW_BIT	(1UL << 54)
#endif /* _ASM_IA64_VT_PAL_H */
