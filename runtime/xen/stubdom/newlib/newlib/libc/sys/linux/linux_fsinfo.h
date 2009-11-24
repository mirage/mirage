/* Constants from kernel header for various FSes.
   Copyright (C) 1998, 1999, 2000, 2001 Free Software Foundation, Inc.
   This file is part of the GNU C Library.

   The GNU C Library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 2.1 of the License, or (at your option) any later version.

   The GNU C Library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Lesser General Public License for more details.

   You should have received a copy of the GNU Lesser General Public
   License along with the GNU C Library; if not, write to the Free
   Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA
   02111-1307 USA.  */

#ifndef _LINUX_FSINFO_H
#define _LINUX_FSINFO_H	1

/* These definitions come from the kernel headers.  But we cannot
   include the headers here because of type clashes.  If new
   filesystem types will become available we have to add the
   appropriate definitions here.*/

/* Constants that identify the `adfs' filesystem.  */
#define ADFS_SUPER_MAGIC	0xadf5

/* Constants that identify the `affs' filesystem.  */
#define AFFS_SUPER_MAGIC	0xadff

/* Constants that identify the `bfs' filesystem.  */
#define BFS_MAGIC		0x1BADFACE

/* Constants that identify the `coda' filesystem.  */
#define CODA_SUPER_MAGIC	0x73757245

/* Constants that identify the `coherent' filesystem.  */
#define COH_SUPER_MAGIC		0x012ff7b7

/* Constant that identifies the `devfs' filesystem.  */
#define DEVFS_SUPER_MAGIC	0x1373

/* Constant that identifies the `devpts' filesystem.  */
#define DEVPTS_SUPER_MAGIC	0x1cd1

/* Constant that identifies the `efs' filesystem.  */
#define EFS_SUPER_MAGIC		0x414A53

/* Constant that identifies the `ext2' and `ext3' filesystems.  */
#define EXT2_SUPER_MAGIC	0xef53

/* Constant that identifies the `hpfs' filesystem.  */
#define HPFS_SUPER_MAGIC	0xf995e849

/* Constant that identifies the `iso9660' filesystem.  */
#define ISOFS_SUPER_MAGIC	0x9660

/* Constants that identify the `minix2' filesystem.  */
#define MINIX2_SUPER_MAGIC	0x2468
#define MINIX2_SUPER_MAGIC2	0x2478

/* Constants that identify the `minix' filesystem.  */
#define MINIX_SUPER_MAGIC	0x137f
#define MINIX_SUPER_MAGIC2	0x138F

/* Constants that identify the `msdos' filesystem.  */
#define MSDOS_SUPER_MAGIC	0x4d44

/* Constants that identify the `ncp' filesystem.  */
#define NCP_SUPER_MAGIC		0x564c

/* Constants that identify the `nfs' filesystem.  */
#define NFS_SUPER_MAGIC		0x6969

/* Constants that identify the `proc' filesystem.  */
#define PROC_SUPER_MAGIC	0x9fa0

/* Constants that identify the `qnx4' filesystem.  */
#define QNX4_SUPER_MAGIC	0x002f

/* Constants that identify the `reiser' filesystem.  */
#define REISERFS_SUPER_MAGIC	0x52654973

/* Constants that identify the `smb' filesystem.  */
#define SMB_SUPER_MAGIC		0x517b

/* Constants that identify the `sysV' filesystem.  */
#define SYSV2_SUPER_MAGIC	0x012ff7b6
#define SYSV4_SUPER_MAGIC	0x012ff7b5

/* Constants that identify the `ufs' filesystem.  */
#define UFS_MAGIC		0x00011954
#define UFS_CIGAM		0x54190100 /* byteswapped MAGIC */

/* Constants that identify the `xenix' filesystem.  */
#define XENIX_SUPER_MAGIC	0x012ff7b4

/* Constant that identifies the `shm' filesystem.  */
#define SHMFS_SUPER_MAGIC	0x01021994

/* Maximum link counts.  */
#define COH_LINK_MAX		10000
#define EXT2_LINK_MAX		32000
#define MINIX2_LINK_MAX		65530
#define MINIX_LINK_MAX		250
#define REISERFS_LINK_MAX	64535
#define SYSV_LINK_MAX		126     /* 127? 251? */
#define UFS_LINK_MAX		EXT2_LINK_MAX
#define XENIX_LINK_MAX		126     /* ?? */

#endif	/* linux_fsinfo.h */
