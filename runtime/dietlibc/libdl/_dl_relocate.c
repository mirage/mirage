#include "_dl_int.h"

#include "_dl_rel.h"

#if 0
/*--- are other relocation types vital to shared objects ? ---*/

  R_386_NONE		 0	/* No reloc */
  R_386_32		 1	/* Direct 32 bit  */
  R_386_COPY		 5	/* Copy symbol at runtime ?!? */
  R_386_GLOB_DAT	 6	/* Create GOT entry */
  R_386_JMP_SLOT	 7	/* Create PLT entry */
  R_386_RELATIVE	 8	/* Adjust by program base */

  R_X86_64_NONE		 0	* No reloc */
  R_X86_64_64		 1	* Direct 64 bit  */
  R_X86_64_COPY		 5	* Copy symbol at runtime */
  R_X86_64_GLOB_DAT	 6	* Create GOT entry */
  R_X86_64_JUMP_SLOT	 7	* Create PLT entry */
  R_X86_64_RELATIVE	 8	* Adjust by program base */
  R_X86_64_32		10	* Direct 32 bit zero extended */

  R_ARM_NONE		 0	/* No reloc */
  R_ARM_ABS32		 2	/* Direct 32 bit  */
  R_ARM_COPY		20	/* Copy symbol at runtime */
  R_ARM_GLOB_DAT	21	/* Create GOT entry */
  R_ARM_JUMP_SLOT	22	/* Create PLT entry */
  R_ARM_RELATIVE	23	/* Adjust by program base */

#endif

static int _dl_apply_relocate(struct _dl_handle*dh,_dl_rel_t*rel) {
  int typ,ret=0;
  Elf_Addr*loc;

  loc=(Elf_Addr *)(dh->mem_base+rel->r_offset);

#ifdef DEBUG
#if 0
  pf(__FUNCTION__); pf(": "); ph(ELF_R_TYPE(rel->r_info)); pf(" @ "); ph((unsigned long)loc);
  pf(" preval "); ph(*(unsigned long*)loc); pf("\n");
#endif
#endif

  typ=ELF_R_TYPE(rel->r_info);

#ifdef __i386__
  if (typ==R_386_32) {			/* 1 */
    unsigned long value=(unsigned long)(dh->dyn_sym_tab[ELF_R_SYM(rel->r_info)].st_value);
#ifdef DEBUG
    pf(__func__); pf(" value "); ph(value); pf("\n");
#endif
    if (value)
      *loc=(unsigned long)(dh->mem_base+value);
    else
      *loc=(unsigned long)_dl_sym(dh,ELF_R_SYM(rel->r_info));
  } else if (typ==R_386_COPY)  {	/* 5 */
    unsigned long len=dh->dyn_sym_tab[ELF_R_SYM(rel->r_info)].st_size;
    void*from=_dl_sym_next(dh,ELF_R_SYM(rel->r_info));
#ifdef DEBUG
    pf(__FUNCTION__); pf(": R_386_COPY from "); ph((unsigned long)from); pf("\n");
#endif
    _dl_lib_memcpy(loc,from,len);
  } else if (typ==R_386_GLOB_DAT) {	/* 6 */
    *loc=(unsigned long)_dl_sym(dh,ELF_R_SYM(rel->r_info));
  } else if (typ==R_386_JMP_SLOT) {	/* 7 */
    *loc+=(unsigned long)dh->mem_base;
  } else if (typ==R_386_RELATIVE) {	/* 8 */
    *loc+=(unsigned long)dh->mem_base;
  } else if (typ==R_386_NONE) {		/* 0 */
  } else
    ret=1;
#endif
#ifdef __arm__
  if (typ==R_ARM_ABS32) {		/*  2 */
    unsigned long value=(unsigned long)(dh->dyn_sym_tab[ELF_R_SYM(rel->r_info)].st_value);
    if (value)
      *loc=(unsigned long)(dh->mem_base+value);
    else
      *loc=(unsigned long)_dl_sym(dh,ELF_R_SYM(rel->r_info));
  } else if (typ==R_ARM_COPY)  {	/* 20 */
    unsigned long len=dh->dyn_sym_tab[ELF_R_SYM(rel->r_info)].st_size;
    void*from=_dl_sym_next(dh,ELF_R_SYM(rel->r_info));
#ifdef DEBUG
    pf(__FUNCTION__); pf(": R_ARM_COPY from "); ph((unsigned long)from); pf("\n");
#endif
    _dl_lib_memcpy(loc,from,len);
  } else if (typ==R_ARM_GLOB_DAT) {	/* 21 */
    *loc=(unsigned long)_dl_sym(dh,ELF_R_SYM(rel->r_info));
  } else if (typ==R_ARM_JUMP_SLOT) {	/* 22 */
    *loc+=(unsigned long)dh->mem_base;
  } else if (typ==R_ARM_RELATIVE) {	/* 23 */
    *loc+=(unsigned long)dh->mem_base;
  } else if (typ==R_ARM_NONE) {		/*  0 */
  } else
    ret=1;
#endif
#ifdef __x86_64__
  if (typ==R_X86_64_64) {			/* 1 */
    unsigned long value=(unsigned long)(dh->dyn_sym_tab[ELF_R_SYM(rel->r_info)].st_value);
    if (value)
      *loc=(unsigned long)(dh->mem_base+value);
    else
      *loc=(unsigned long)_dl_sym(dh,ELF_R_SYM(rel->r_info));
  } else if (typ==R_X86_64_COPY)  {	/* 5 */
    unsigned long len=dh->dyn_sym_tab[ELF_R_SYM(rel->r_info)].st_size;
    void*from=_dl_sym_next(dh,ELF_R_SYM(rel->r_info));
#ifdef DEBUG
    pf(__FUNCTION__); pf(": R_X86_64_COPY from "); ph((unsigned long)from); pf("\n");
#endif
    _dl_lib_memcpy(loc,from,len);
  } else if (typ==R_X86_64_GLOB_DAT) {	/* 6 */
    *loc=(unsigned long)_dl_sym(dh,ELF_R_SYM(rel->r_info));
  } else if (typ==R_X86_64_JUMP_SLOT) {	/* 7 */
    *loc=((unsigned long)dh->mem_base)+rel->r_addend;
  } else if (typ==R_X86_64_RELATIVE) {	/* 8 */
    *loc=((unsigned long)dh->mem_base)+rel->r_addend;
  } else if (typ==R_X86_64_32) {	/* 10 */
    *loc=((unsigned long)(dh->mem_base+dh->dyn_sym_tab[ELF_R_SYM(rel->r_info)].st_value))&0xffffffffUL;
  } else if (typ==R_X86_64_NONE) {	/* 0 */
  } else
    ret=1;
#endif

#ifdef DEBUG
  pf(__FUNCTION__); pf(": @ "); ph((unsigned long)loc); pf(" val "); ph(*(unsigned long*)loc); pf("\n");
#endif
  return ret;
}

#ifdef __DIET_LD_SO__
static
#endif
int _dl_relocate(struct _dl_handle*dh,_dl_rel_t *rel,int num) {
  int i;
  for (i=0;i<num;i++) {
    if (_dl_apply_relocate(dh,rel+i)) {
      _dl_error=4;
      return 1;
    }
  }
  return 0;
}
