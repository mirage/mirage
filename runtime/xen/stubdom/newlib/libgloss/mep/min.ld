/*
 * Copyright (c) 2000  Red Hat, Inc. All rights reserved.
 * 
 * This copyrighted material is made available to anyone wishing to use, modify,
 * copy, or redistribute it subject to the terms and conditions of the BSD 
 * License.   This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY expressed or implied, including the implied 
 * warranties of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  A copy
 * of this license is available at http://www.opensource.org/licenses. Any 
 * Red Hat trademarks that are incorporated in the source code or documentation
 * are not subject to the BSD License and may only be used or replicated with
 * the express permission of Red Hat, Inc.
 */
OUTPUT_FORMAT("elf32-mep", "elf32-mep",
	      "elf32-mep")
OUTPUT_ARCH(mep)
ENTRY(_start)
SECTIONS
{
  /* Read-only sections, merged into text segment: */
  . = 0x0080000;
  .gnu.version   : { *(.gnu.version)	}
  .gnu.version_d   : { *(.gnu.version_d)	}
  .gnu.version_r   : { *(.gnu.version_r)	}
  .init          : 
  { 
    KEEP (*(.init))
  } =0
  .plt      : { *(.plt)	}
  .text      :
  {
    *(.text)
    *(.text.*)
    *(.stub)
    /* .gnu.warning sections are handled specially by elf32.em.  */
    *(.gnu.warning)
    *(.gnu.linkonce.t.*)
    *(.ftext) *(.ftext.*) *(.gnu.linkonce.ft.*)
    . = ALIGN(8);
    *(.vftext) *(.vftext.*) *(.gnu.linkonce.vf.*)
    *(.frodata) *(.frodata.*) *(.gnu.linkonce.frd.*)
  } =0
  .fini      :
  {
    KEEP (*(.fini))
  } =0
  PROVIDE (__etext = .);
  PROVIDE (_etext = .);
  PROVIDE (etext = .);
  .rodata   : { *(.rodata) *(.rodata.*) *(.gnu.linkonce.r.*) }
  .rodata1   : { *(.rodata1) }

  __stack_size = 0x100000;
  __stack0  = (__stack - (0 *  (__stack_size / 1)) + 15) / 16 * 16;

  .rostacktab : 
  {
    /* Emit a table describing the location of the different stacks.
       Only 1 processor in the default configuration.  */
    . = ALIGN(4);
    __stack_table = .;
    LONG (__stack0);
  }

  .sdata2   : { *(.sdata2) *(.sdata2.*) *(.gnu.linkonce.s2.*) }
  .sbss2   : { *(.sbss2) *(.sbss2.*) *(.gnu.linkonce.sb2.*) }
  /* Adjust the address for the data segment.  We want to adjust up to
     the same address within the page on the next page up.  */
  . = ALIGN(256) + (. & (256 - 1));
  .data    :
  {
    __data_start = . ;
    *(.data)
    *(.data.*)
    *(.gnu.linkonce.d.*)
    SORT(CONSTRUCTORS)
  }
  .data1   : { *(.data1) }
  .eh_frame : { KEEP (*(.eh_frame)) }
  .gcc_except_table : { *(.gcc_except_table) *(.gcc_except_table.*) }
  . = ALIGN(4);
  __tpbase = .;
  .based : { *(.based) *(.based.*) *(.gnu.linkonce.based.*) }
  .far : { *(.far) *(.far.*) *(.gnu.linkonce.far.*) }
  .dynamic       : { *(.dynamic) }
  .ctors   : 
  {
    /* gcc uses crtbegin.o to find the start of
       the constructors, so we make sure it is
       first.  Because this is a wildcard, it
       doesn't matter if the user does not
       actually link against crtbegin.o; the
       linker won't look for a file to match a
       wildcard.  The wildcard also means that it
       doesn't matter which directory crtbegin.o
       is in.  */
    KEEP (*crtbegin.o(.ctors))
    /* We don't want to include the .ctor section from
       from the crtend.o file until after the sorted ctors.
       The .ctor section from the crtend file contains the
       end of ctors marker and it must be last */
    KEEP (*(EXCLUDE_FILE (*crtend.o ) .ctors))
    KEEP (*(SORT(.ctors.*)))
    KEEP (*(.ctors))
  }
   .dtors         :
  {
    KEEP (*crtbegin.o(.dtors))
    KEEP (*(EXCLUDE_FILE (*crtend.o ) .dtors))
    KEEP (*(SORT(.dtors.*)))
    KEEP (*(.dtors))
  }
  . = ALIGN(4);
  __sdabase = . + 0x8000;
  .got		  : { *(.got.plt) *(.got) }
  /* We want the small data sections together, so single-instruction offsets
     can access them all, and initialized data all before uninitialized, so
     we can shorten the on-disk segment size.  */
  .srodata : { *(.srodata) *(.srodata.*) *(.gnu.linkonce.srd.*) }
  .sdata     : 
  {
    *(.sdata) 
    *(.sdata.*)
    *(.gnu.linkonce.s.*)
  }
  _edata = .;
  PROVIDE (edata = .);
  __bss_start = .;
  .sbss      :
  {
    PROVIDE (__sbss_start = .);
    PROVIDE (___sbss_start = .);
    *(.dynsbss)
    *(.sbss)
    *(.sbss.*)
    *(.gnu.linkonce.sb.*)
    *(.scommon)
    PROVIDE (__sbss_end = .);
    PROVIDE (___sbss_end = .);
  }
  .bss       :
  {
   *(.dynbss)
   *(.bss)
   *(.bss.*)
   *(.gnu.linkonce.b.*)
   *(COMMON)
   /* Align here to ensure that the .bss section occupies space up to
      _end.  Align after .bss to ensure correct alignment even if the
      .bss section disappears because there are no input sections.  */
   . = ALIGN(32 / 8);
  }
  .farbss : { PROVIDE (__farbss_start = .); *(.farbss) *(.farbss.*) PROVIDE (__farbss_end = .); }
  . = ALIGN(32 / 8);
  _end = .;
  PROVIDE (end = .);

  __stack = 0x00effff0;
  PROVIDE (__heap  = 0x00f00000);

  /* Stabs debugging sections.  */
  .stab 0 : { *(.stab) }
  .stabstr 0 : { *(.stabstr) }
  .stab.excl 0 : { *(.stab.excl) }
  .stab.exclstr 0 : { *(.stab.exclstr) }
  .stab.index 0 : { *(.stab.index) }
  .stab.indexstr 0 : { *(.stab.indexstr) }
  .comment 0 : { *(.comment) }
  /* DWARF debug sections.
     Symbols in the DWARF debugging sections are relative to the beginning
     of the section so we begin them at 0.  */
  /* DWARF 1 */
  .debug          0 : { *(.debug) }
  .line           0 : { *(.line) }
  /* GNU DWARF 1 extensions */
  .debug_srcinfo  0 : { *(.debug_srcinfo) }
  .debug_sfnames  0 : { *(.debug_sfnames) }
  /* DWARF 1.1 and DWARF 2 */
  .debug_aranges  0 : { *(.debug_aranges) }
  .debug_pubnames 0 : { *(.debug_pubnames) }
  /* DWARF 2 */
  .debug_info     0 : { *(.debug_info) *(.gnu.linkonce.wi.*) }
  .debug_abbrev   0 : { *(.debug_abbrev) }
  .debug_line     0 : { *(.debug_line) }
  .debug_frame    0 : { *(.debug_frame) }
  .debug_str      0 : { *(.debug_str) }
  .debug_loc      0 : { *(.debug_loc) }
  .debug_macinfo  0 : { *(.debug_macinfo) }
  .debug_ranges   0 : { *(.debug_ranges) }
  /* SGI/MIPS DWARF 2 extensions */
  .debug_weaknames 0 : { *(.debug_weaknames) }
  .debug_funcnames 0 : { *(.debug_funcnames) }
  .debug_typenames 0 : { *(.debug_typenames) }
  .debug_varnames  0 : { *(.debug_varnames) }
  /* These must appear regardless of  .  */
}
