/* Linux/i386 version of processor capability information handling macros.
   Copyright (C) 1998, 1999, 2000, 2001 Free Software Foundation, Inc.
   This file is part of the GNU C Library.
   Contributed by Ulrich Drepper <drepper@cygnus.com>, 1998.

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

#ifndef _DL_PROCINFO_H
#define _DL_PROCINFO_H	1

#include <ldsodefs.h>

/* If anything should be added here check whether the size of each string
   is still ok with the given array size.  */
extern const char _dl_x86_cap_flags[][7];
#define _DL_HWCAP_COUNT 32

extern const char _dl_x86_platforms[][5];
#define _DL_PLATFORMS_COUNT	4

/* Start at 48 to reserve some space.  */
#define _DL_FIRST_PLATFORM	48
/* Mask to filter out platforms.  */
#define _DL_HWCAP_PLATFORM	(7ULL << _DL_FIRST_PLATFORM)


static inline int
__attribute__ ((unused))
_dl_procinfo (int word)
{
  /* This table should match the information from arch/i386/kernel/setup.c
     in the kernel sources.  */
  int i;

  _dl_printf ("AT_HWCAP:   ");

  for (i = 0; i < _DL_HWCAP_COUNT; ++i)
    if (word & (1 << i))
      _dl_printf (" %s", _dl_x86_cap_flags[i]);

  _dl_printf ("\n");

  return 0;
}

static inline const char *
__attribute__ ((unused))
_dl_hwcap_string (int idx)
{
  return _dl_x86_cap_flags[idx];
};

static inline const char *
__attribute__ ((unused))
_dl_platform_string (int idx)
{
  return _dl_x86_platforms [idx - _DL_FIRST_PLATFORM];
};

enum
{
  HWCAP_I386_FPU   = 1 << 0,
  HWCAP_I386_VME   = 1 << 1,
  HWCAP_I386_DE    = 1 << 2,
  HWCAP_I386_PSE   = 1 << 3,
  HWCAP_I386_TSC   = 1 << 4,
  HWCAP_I386_MSR   = 1 << 5,
  HWCAP_I386_PAE   = 1 << 6,
  HWCAP_I386_MCE   = 1 << 7,
  HWCAP_I386_CX8   = 1 << 8,
  HWCAP_I386_APIC  = 1 << 9,
  HWCAP_I386_SEP   = 1 << 11,
  HWCAP_I386_MTRR  = 1 << 12,
  HWCAP_I386_PGE   = 1 << 13,
  HWCAP_I386_MCA   = 1 << 14,
  HWCAP_I386_CMOV  = 1 << 15,
  HWCAP_I386_FCMOV = 1 << 16,
  HWCAP_I386_MMX   = 1 << 23,
  HWCAP_I386_OSFXSR = 1 << 24,
  HWCAP_I386_XMM   = 1 << 25,
  HWCAP_I386_XMM2  = 1 << 26,
  HWCAP_I386_AMD3D = 1 << 31,

  /* XXX Which others to add here?  */
  HWCAP_IMPORTANT = (HWCAP_I386_MMX)

};

static inline int
__attribute__ ((unused))
_dl_string_hwcap (const char *str)
{
  int i;

  for (i = 0; i < _DL_HWCAP_COUNT; i++)
    {
      if (strcmp (str, _dl_x86_cap_flags[i]) == 0)
	return i;
    }
  return -1;
};


static inline int
__attribute__ ((unused))
_dl_string_platform (const char *str)
{
  int i;

  if (str != NULL)
    for (i = 0; i < _DL_PLATFORMS_COUNT; ++i)
      {
	if (strcmp (str, _dl_x86_platforms[i]) == 0)
	  return _DL_FIRST_PLATFORM + i;
      }
  return -1;
};

#endif /* dl-procinfo.h */
