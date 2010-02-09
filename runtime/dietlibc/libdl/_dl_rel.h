#ifndef ___DL_REL_H__
#define ___DL_REL_H__

#if defined(__arm__) || defined(__i386__) || defined(__mips__)
/* this are REL only archs: arm, i386, mips */

#define _dl_rel_t	Elf_Rel
#define _DL_REL_T	DT_REL

#define _DL_REL_PLT(b,r)	(*(unsigned long*)((b)+(r)->r_offset)+=(unsigned long)(b))

#elif defined(__alpha__) || defined(__hppa__) || defined(__powerpc__) || defined(__sparc__) || defined(__s390__) \
  || defined(__x86_64__)
/* this are RELA only archs: alpha, chris, hppa, ia64, m68k, ppc, sparc, sparc64, sh, s390, x86_64 */

#define _dl_rel_t	Elf_Rela
#define _DL_REL_T	DT_RELA

#define _DL_REL_PLT(b,r)	(*(unsigned long*)((b)+(r)->r_offset)+=(unsigned long)(b))
//#define _DL_REL_PLT(b,r)	(*(unsigned long*)((b)+(r)->r_offset)=(unsigned long)((b)+(r)->r_addend))

#else
/* there are no known linux supported arch with mixed relocation types ... */
#error "_dl_rel.h: NOT SUPPORTED"
#endif

#endif
