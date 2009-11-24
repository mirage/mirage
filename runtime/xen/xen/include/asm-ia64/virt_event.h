#ifndef __VIRT_EVENT_H__
#define __VIRT_EVENT_H__

/* -*-  Mode:C; c-basic-offset:4; tab-width:4; indent-tabs-mode:nil -*- */
/*
 * virt_event.h:
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
 *  Shaofan Li (Susie Li) (susie.li@intel.com)
 *  Xuefei Xu (Anthony Xu) (Anthony.xu@intel.com)
 */


#define EVENT_MOV_TO_AR			 1
#define EVENT_MOV_TO_AR_IMM		 2
#define EVENT_MOV_FROM_AR		 3
#define EVENT_MOV_TO_CR			 4
#define EVENT_MOV_FROM_CR		 5
#define EVENT_MOV_TO_PSR		 6
#define EVENT_MOV_FROM_PSR		 7
#define EVENT_ITC_D			 8
#define EVENT_ITC_I			 9
#define EVENT_MOV_TO_RR			 10
#define EVENT_MOV_TO_DBR		 11
#define EVENT_MOV_TO_IBR		 12
#define EVENT_MOV_TO_PKR		 13
#define EVENT_MOV_TO_PMC		 14
#define EVENT_MOV_TO_PMD		 15
#define EVENT_ITR_D			 16
#define EVENT_ITR_I			 17
#define EVENT_MOV_FROM_RR		 18
#define EVENT_MOV_FROM_DBR		 19
#define EVENT_MOV_FROM_IBR		 20
#define EVENT_MOV_FROM_PKR		 21
#define EVENT_MOV_FROM_PMC		 22
#define EVENT_MOV_FROM_CPUID		 23
#define EVENT_SSM			 24
#define EVENT_RSM			 25
#define EVENT_PTC_L			 26
#define EVENT_PTC_G			 27
#define EVENT_PTC_GA			 28
#define EVENT_PTR_D			 29
#define EVENT_PTR_I			 30
#define EVENT_THASH			 31
#define EVENT_TTAG			 32
#define EVENT_TPA			 33
#define EVENT_TAK			 34
#define EVENT_PTC_E			 35
#define EVENT_COVER			 36
#define EVENT_RFI			 37
#define EVENT_BSW_0			 38
#define EVENT_BSW_1			 39
#define EVENT_VMSW			 40

#if 0
/* VMAL 1.0 */
#define EVENT_MOV_TO_AR			 1
#define EVENT_MOV_TO_AR_IMM		 2
#define EVENT_MOV_FROM_AR		 3
#define EVENT_MOV_TO_CR			 4
#define EVENT_MOV_FROM_CR		 5
#define EVENT_MOV_TO_PSR		 6
#define EVENT_MOV_FROM_PSR		 7
#define EVENT_ITC_D			 8
#define EVENT_ITC_I			 9
#define EVENT_MOV_TO_RR			 10
#define EVENT_MOV_TO_DBR		 11
#define EVENT_MOV_TO_IBR		 12
#define EVENT_MOV_TO_PKR		 13
#define EVENT_MOV_TO_PMC		 14
#define EVENT_MOV_TO_PMD		 15
#define EVENT_ITR_D			 16
#define EVENT_ITR_I			 17
#define EVENT_MOV_FROM_RR		 18
#define EVENT_MOV_FROM_DBR		 19
#define EVENT_MOV_FROM_IBR		 20
#define EVENT_MOV_FROM_PKR		 21
#define EVENT_MOV_FROM_PMC		 22
#define EVENT_MOV_FROM_PMD		 23
#define EVENT_MOV_FROM_CPUID		 24
#define EVENT_SSM			 25
#define EVENT_RSM			 26
#define EVENT_PTC_L			 27
#define EVENT_PTC_G			 28
#define EVENT_PTC_GA			 29
#define EVENT_PTR_D			 30
#define EVENT_PTR_I			 31
#define EVENT_THASH			 32
#define EVENT_TTAG			 33
#define EVENT_TPA			 34
#define EVENT_TAK			 35
#define EVENT_PTC_E			 36
#define EVENT_COVER			 37
#define EVENT_RFI			 38
#define EVENT_BSW_0			 39
#define EVENT_BSW_1			 40
#define EVENT_VMSW			 41


#endif  /*  VMAL 2.0 */
#endif	/* __VIRT_EVENT_H__ */ 
