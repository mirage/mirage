/* Machine-dependent ELF dynamic relocation inline functions.  i386 version.
   Copyright (C) 1995,96,97,98,99,2000,2001 Free Software Foundation, Inc.
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

#ifndef dl_machine_h
#define dl_machine_h

#define ELF_MACHINE_NAME "i386"

#include <sys/param.h>
#include <machine/weakalias.h>

/* Return nonzero iff ELF header is compatible with the running host.  */
static inline int __attribute__ ((unused))
elf_machine_matches_host (const Elf32_Ehdr *ehdr)
{
  return ehdr->e_machine == EM_386;
}


/* Return the link-time address of _DYNAMIC.  Conveniently, this is the
   first element of the GOT.  This must be inlined in a function which
   uses global data.  */
static inline Elf32_Addr __attribute__ ((unused))
elf_machine_dynamic (void)
{
  register Elf32_Addr *got asm ("%ebx");
  return *got;
}


/* Return the run-time load address of the shared object.  */
static inline Elf32_Addr __attribute__ ((unused))
elf_machine_load_address (void)
{
  Elf32_Addr addr;
  asm ("leal _dl_start@GOTOFF(%%ebx), %0\n"
       "subl _dl_start@GOT(%%ebx), %0"
       : "=r" (addr) : : "cc");
  return addr;
}

#if !defined PROF && !__BOUNDED_POINTERS__
/* We add a declaration of this function here so that in dl-runtime.c
   the ELF_MACHINE_RUNTIME_TRAMPOLINE macro really can pass the parameters
   in registers.

   We cannot use this scheme for profiling because the _mcount call
   destroys the passed register information.  */
/* GKM FIXME: Fix trampoline to pass bounds so we can do
   without the `__unbounded' qualifier.  */
static ElfW(Addr) fixup (struct link_map *__unbounded l, ElfW(Word) reloc_offset)
     __attribute__ ((regparm (2), unused));
static ElfW(Addr) profile_fixup (struct link_map *l, ElfW(Word) reloc_offset,
				 ElfW(Addr) retaddr)
     __attribute__ ((regparm (3), unused));
#endif

/* Set up the loaded object described by L so its unrelocated PLT
   entries will jump to the on-demand fixup code in dl-runtime.c.  */

static inline int __attribute__ ((unused))
elf_machine_runtime_setup (struct link_map *l, int lazy, int profile)
{
  Elf32_Addr *got;
  extern void _dl_runtime_resolve (Elf32_Word);
  extern void _dl_runtime_profile (Elf32_Word);

  if (l->l_info[DT_JMPREL] && lazy)
    {
      /* The GOT entries for functions in the PLT have not yet been filled
	 in.  Their initial contents will arrange when called to push an
	 offset into the .rel.plt section, push _GLOBAL_OFFSET_TABLE_[1],
	 and then jump to _GLOBAL_OFFSET_TABLE[2].  */
      got = (Elf32_Addr *) D_PTR (l, l_info[DT_PLTGOT]);
      got[1] = (Elf32_Addr) l;	/* Identify this shared object.  */

      /* The got[2] entry contains the address of a function which gets
	 called to get the address of a so far unresolved function and
	 jump to it.  The profiling extension of the dynamic linker allows
	 to intercept the calls to collect information.  In this case we
	 don't store the address in the GOT so that all future calls also
	 end in this function.  */
      if (__builtin_expect (profile, 0))
	{
	  got[2] = (Elf32_Addr) &_dl_runtime_profile;

	  if (_dl_name_match_p (_dl_profile, l))
	    /* This is the object we are looking for.  Say that we really
	       want profiling and the timers are started.  */
	    _dl_profile_map = l;
	}
      else
	/* This function will get called to fix up the GOT entry indicated by
	   the offset on the stack, and then jump to the resolved address.  */
	got[2] = (Elf32_Addr) &_dl_runtime_resolve;
    }

  return lazy;
}

/* This code is used in dl-runtime.c to call the `fixup' function
   and then redirect to the address it returns.  */
#if !defined PROF && !__BOUNDED_POINTERS__
# define ELF_MACHINE_RUNTIME_TRAMPOLINE asm ("\
	.text\n\
	.globl _dl_runtime_resolve\n\
	.type _dl_runtime_resolve, @function\n\
	.align 16\n\
_dl_runtime_resolve:\n\
	pushl %eax		# Preserve registers otherwise clobbered.\n\
	pushl %ecx\n\
	pushl %edx\n\
	movl 16(%esp), %edx	# Copy args pushed by PLT in register.  Note\n\
	movl 12(%esp), %eax	# that `fixup' takes its parameters in regs.\n\
	call fixup		# Call resolver.\n\
	popl %edx		# Get register content back.\n\
	popl %ecx\n\
	xchgl %eax, (%esp)	# Get %eax contents end store function address.\n\
	ret $8			# Jump to function address.\n\
	.size _dl_runtime_resolve, .-_dl_runtime_resolve\n\
\n\
	.globl _dl_runtime_profile\n\
	.type _dl_runtime_profile, @function\n\
	.align 16\n\
_dl_runtime_profile:\n\
	pushl %eax		# Preserve registers otherwise clobbered.\n\
	pushl %ecx\n\
	pushl %edx\n\
	movl 20(%esp), %ecx	# Load return address\n\
	movl 16(%esp), %edx	# Copy args pushed by PLT in register.  Note\n\
	movl 12(%esp), %eax	# that `fixup' takes its parameters in regs.\n\
	call profile_fixup	# Call resolver.\n\
	popl %edx		# Get register content back.\n\
	popl %ecx\n\
	xchgl %eax, (%esp)	# Get %eax contents end store function address.\n\
	ret $8			# Jump to function address.\n\
	.size _dl_runtime_profile, .-_dl_runtime_profile\n\
	.previous\n\
");
#else
# define ELF_MACHINE_RUNTIME_TRAMPOLINE asm ("\n\
	.text\n\
	.globl _dl_runtime_resolve\n\
	.globl _dl_runtime_profile\n\
	.type _dl_runtime_resolve, @function\n\
	.type _dl_runtime_profile, @function\n\
	.align 16\n\
_dl_runtime_resolve:\n\
_dl_runtime_profile:\n\
	pushl %eax		# Preserve registers otherwise clobbered.\n\
	pushl %ecx\n\
	pushl %edx\n\
	movl 16(%esp), %edx	# Push the arguments for `fixup'\n\
	movl 12(%esp), %eax\n\
	pushl %edx\n\
	pushl %eax\n\
	call fixup		# Call resolver.\n\
	popl %edx		# Pop the parameters\n\
	popl %ecx\n\
	popl %edx		# Get register content back.\n\
	popl %ecx\n\
	xchgl %eax, (%esp)	# Get %eax contents end store function address.\n\
	ret $8			# Jump to function address.\n\
	.size _dl_runtime_resolve, .-_dl_runtime_resolve\n\
	.size _dl_runtime_profile, .-_dl_runtime_profile\n\
	.previous\n\
");
#endif

/* Mask identifying addresses reserved for the user program,
   where the dynamic linker should not map anything.  */
#define ELF_MACHINE_USER_ADDRESS_MASK	0xf8000000UL

/* Initial entry point code for the dynamic linker.
   The C function `_dl_start' is the real entry point;
   its return value is the user program's entry point.  */

#define RTLD_START asm ("\n\
	.text\n\
	.align 16\n\
0:	movl (%esp), %ebx\n\
	ret\n\
	.align 16\n\
.globl _start\n\
.globl _dl_start_user\n\
_start:\n\
	pushl %esp\n\
	call _dl_start\n\
	popl %ebx\n\
_dl_start_user:\n\
	# Save the user entry point address in %edi.\n\
	movl %eax, %edi\n\
	# Point %ebx at the GOT.\n\
	call 0b\n\
	addl $_GLOBAL_OFFSET_TABLE_, %ebx\n\
	# Store the highest stack address\n\
	movl __libc_stack_end@GOT(%ebx), %eax\n\
	movl %esp, (%eax)\n\
	# See if we were run as a command with the executable file\n\
	# name as an extra leading argument.\n\
	movl _dl_skip_args@GOT(%ebx), %eax\n\
	movl (%eax), %eax\n\
	# Pop the original argument count.\n\
	popl %edx\n\
	# Adjust the stack pointer to skip _dl_skip_args words.\n\
	leal (%esp,%eax,4), %esp\n\
	# Subtract _dl_skip_args from argc.\n\
	subl %eax, %edx\n\
	# Push argc back on the stack.\n\
	push %edx\n\
	# The special initializer gets called with the stack just\n\
	# as the application's entry point will see it; it can\n\
	# switch stacks if it moves these contents over.\n\
" RTLD_START_SPECIAL_INIT "\n\
	# Load the parameters again.\n\
	# (eax, edx, ecx, *--esp) = (_dl_loaded, argc, argv, envp)\n\
	movl _dl_loaded@GOT(%ebx), %esi\n\
	leal 8(%esp,%edx,4), %eax\n\
	leal 4(%esp), %ecx\n\
	pushl %eax\n\
	movl (%esi), %eax\n\
	# Call the function to run the initializers.\n\
	call _dl_init@PLT\n\
	# Pass our finalizer function to the user in %edx, as per ELF ABI.\n\
	movl _dl_fini@GOT(%ebx), %edx\n\
	# Jump to the user's entry point.\n\
	jmp *%edi\n\
	.previous\n\
");

#ifndef RTLD_START_SPECIAL_INIT
#define RTLD_START_SPECIAL_INIT /* nothing */
#endif

/* ELF_RTYPE_CLASS_PLT iff TYPE describes relocation of a PLT entry, so
   PLT entries should not be allowed to define the value.
   ELF_RTYPE_CLASS_NOCOPY iff TYPE should not be allowed to resolve to one
   of the main executable's symbols, as for a COPY reloc.  */
#define elf_machine_type_class(type) \
  ((((type) == R_386_JMP_SLOT) * ELF_RTYPE_CLASS_PLT)	\
   | (((type) == R_386_COPY) * ELF_RTYPE_CLASS_COPY))

/* A reloc type used for ld.so cmdline arg lookups to reject PLT entries.  */
#define ELF_MACHINE_JMP_SLOT	R_386_JMP_SLOT

/* The i386 never uses Elf32_Rela relocations.  */
#define ELF_MACHINE_NO_RELA 1

/* We define an initialization functions.  This is called very early in
   _dl_sysdep_start.  */
#define DL_PLATFORM_INIT dl_platform_init ()

extern const char *_dl_platform;

static inline void __attribute__ ((unused))
dl_platform_init (void)
{
  if (_dl_platform != NULL && *_dl_platform == '\0')
    /* Avoid an empty string which would disturb us.  */
    _dl_platform = NULL;
}

static inline Elf32_Addr
elf_machine_fixup_plt (struct link_map *map, lookup_t t,
		       const Elf32_Rel *reloc,
		       Elf32_Addr *reloc_addr, Elf32_Addr value)
{
  return *reloc_addr = value;
}

/* Return the final value of a plt relocation.  */
static inline Elf32_Addr
elf_machine_plt_value (struct link_map *map, const Elf32_Rel *reloc,
		       Elf32_Addr value)
{
  return value;
}

static inline void __attribute__ ((unused))
elf_machine_rel (struct link_map *map, const Elf32_Rel *reloc,
		 const Elf32_Sym *sym, const struct r_found_version *version,
		 Elf32_Addr *const reloc_addr,
		 struct r_scope_elem *scope[]);

static inline void __attribute__ ((unused))
elf_machine_rel_relative (Elf32_Addr l_addr, const Elf32_Rel *reloc,
			  Elf32_Addr *const reloc_addr);

static inline void
elf_machine_lazy_rel (struct link_map *map,
		      Elf32_Addr l_addr, const Elf32_Rel *reloc);

#endif /* !dl_machine_h */

#ifdef RESOLVE

/* Perform the relocation specified by RELOC and SYM (which is fully resolved).
   MAP is the object containing the reloc.  */

static inline void __attribute__ ((unused))
elf_machine_rel (struct link_map *map, const Elf32_Rel *reloc,
		 const Elf32_Sym *sym, const struct r_found_version *version,
		 Elf32_Addr *const reloc_addr,
		 struct r_scope_elem *scope[])
{
  const unsigned int r_type = ELF32_R_TYPE (reloc->r_info);

#if !defined RTLD_BOOTSTRAP || !defined HAVE_Z_COMBRELOC
  if (__builtin_expect (r_type == R_386_RELATIVE, 0))
    {
# if !defined RTLD_BOOTSTRAP && !defined HAVE_Z_COMBRELOC
      /* This is defined in rtld.c, but nowhere in the static libc.a;
	 make the reference weak so static programs can still link.
	 This declaration cannot be done when compiling rtld.c
	 (i.e. #ifdef RTLD_BOOTSTRAP) because rtld.c contains the
	 common defn for _dl_rtld_map, which is incompatible with a
	 weak decl in the same file.  */
      #pragma weak _dl_rtld_map
      if (map != &_dl_rtld_map) /* Already done in rtld itself.  */
# endif
	*reloc_addr += map->l_addr;
    }
# ifndef RTLD_BOOTSTRAP
  else if (__builtin_expect (r_type == R_386_NONE, 0))
    return;
# endif
  else
#endif
    {
#ifndef RTLD_BOOTSTRAP
      const Elf32_Sym *const refsym = sym;
#endif
      /* String table object symbols.  */
      const char *strtab = (const void *) D_PTR (map, l_info[DT_STRTAB]);
      Elf32_Addr value = RESOLVE (&sym, version, r_type, scope);
      if (sym)
	value += sym->st_value;

#ifdef RTLD_BOOTSTRAP
      assert (r_type == R_386_GLOB_DAT || r_type == R_386_JMP_SLOT);
      *reloc_addr = value;
#else
      switch (r_type)
	{
	case R_386_GLOB_DAT:
	case R_386_JMP_SLOT:
	  *reloc_addr = value;
	  break;
	case R_386_32:
	  *reloc_addr += value;
	  break;
	case R_386_PC32:
	  *reloc_addr += (value - (Elf32_Addr) reloc_addr);
	  break;
	case R_386_COPY:
	  if (sym == NULL)
	    /* This can happen in trace mode if an object could not be
	       found.  */
	    break;
	  if (__builtin_expect (sym->st_size > refsym->st_size, 0)
	      || (__builtin_expect (sym->st_size < refsym->st_size, 0)
		  && _dl_verbose))
	    {
	      const char *strtab;

	      strtab = (const char *) D_PTR (map, l_info[DT_STRTAB]);
	      _dl_error_printf ("\
%s: Symbol `%s' has different size in shared object, consider re-linking\n",
				_dl_argv[0] ?: "<program name unknown>",
				strtab + refsym->st_name);
	    }
	  memcpy (reloc_addr, (void *) value, MIN (sym->st_size,
						   refsym->st_size));
	  break;
	default:
	  _dl_reloc_bad_type (map, r_type, 0);
	  break;
	}
#endif
    }
}

static inline void __attribute__ ((unused))
elf_machine_rel_relative (Elf32_Addr l_addr, const Elf32_Rel *reloc,
			  Elf32_Addr *const reloc_addr)
{
  assert (ELF32_R_TYPE (reloc->r_info) == R_386_RELATIVE);
  *reloc_addr += l_addr;
}

static inline void
elf_machine_lazy_rel (struct link_map *map,
		      Elf32_Addr l_addr, const Elf32_Rel *reloc)
{
  Elf32_Addr *const reloc_addr = (void *) (l_addr + reloc->r_offset);
  const unsigned int r_type = ELF32_R_TYPE (reloc->r_info);
  /* Check for unexpected PLT reloc type.  */
  if (__builtin_expect (r_type == R_386_JMP_SLOT, 1))
    *reloc_addr += l_addr;
  else
    _dl_reloc_bad_type (map, r_type, 1);
}

#endif /* RESOLVE */
