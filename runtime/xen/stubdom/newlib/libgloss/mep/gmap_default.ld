/******************************************************************************
begin-header

   Copyright (c) 2000-2007  Red Hat, Inc. All rights reserved.

   This copyrighted material is made available to anyone wishing to use, modify,
   copy, or redistribute it subject to the terms and conditions of the BSD 
   License.   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY expressed or implied, including the implied 
   warranties of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  A copy
   of this license is available at http://www.opensource.org/licenses. Any 
   Red Hat trademarks that are incorporated in the source code or documentation
   are not subject to the BSD License and may only be used or replicated with
   the express permission of Red Hat, Inc.

   Default linker script for use with the Configuration Tool for
   Toshiba Media Processor.

   When generating a configuration for a media module, M, the
   configuration tool will copy this file into a custom linker script
   M.ld, and customize the script with settings from the media
   module's global map file.

end-header
*******************************************************************************/

OUTPUT_FORMAT("elf32-mep", "elf32-mep",
	      "elf32-mep")
OUTPUT_ARCH(mep)
ENTRY(_reset)

MEMORY
{
/* begin-memory */
  VEC	(r) : ORIGIN = 0x00000000, LENGTH = 0x000000b8
  ROM	(r) : ORIGIN = 0x000000b8, LENGTH = 0x001fff48
  RAM	(w) : ORIGIN = 0x00800000, LENGTH = 0x00800000
/* end-memory */
}

SECTIONS
{
  /* Sections to be placed in the vec area.  */
  .vec : { *(.vec) } >VEC /* VEC-section */

  /* Sections to be placed in the HWINIT area.  */
  .hwinit : { *(.hwinit) } >HWINIT /* HWINIT-section */

  /* Sections to be placed in the ROM area.  */
  .gnu.version   : { *(.gnu.version)	} >ROM /* ROM-section */
  .gnu.version_d : { *(.gnu.version_d)	} >ROM /* ROM-section */
  .gnu.version_r : { *(.gnu.version_r)	} >ROM /* ROM-section */

  /* Sections to be placed in the romdata.s area.  */
  .srodata :
  {
    __sdabase = . + 0x8000;
    *(.srodata) *(.srodata.*) *(.gnu.linkonce.srd.*)
  } >RAM /* DATA-section */

  /* Sections to be placed in the data.s area.  */
  .sdata     : 
  {
    *(.sdata) 
    *(.sdata.*)
    *(.gnu.linkonce.s.*)
  } >RAM /* DATA-section */
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
    /* Assert maximum size */
    __assert_tiny_size = ASSERT ((. < __sdabase) || ((. - __sdabase) <= 0x8000),
	 		         "tiny section overflow");
  } >RAM /* DATA-section */

  /* Sections to be placed in the data.m area.  */
  .data    :
  {
    __data_start = . ;
    *(.data)
    *(.data.*)
    *(.gnu.linkonce.d.*)
    SORT(CONSTRUCTORS)
  } >RAM /* DATA-section */
  .data1   : { *(.data1) } >RAM /* DATA-section */
  .eh_frame : { KEEP (*(.eh_frame))} >RAM /* DATA-section */
  .gcc_except_table : { *(.gcc_except_table) *(.gcc_except_table.*) } >RAM /* DATA-section */
  .dynamic       : { *(.dynamic) } >RAM /* DATA-section */
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
  } >RAM /* DATA-section */
  .dtors         :
  {
    KEEP (*crtbegin.o(.dtors))
    KEEP (*(EXCLUDE_FILE (*crtend.o ) .dtors))
    KEEP (*(SORT(.dtors.*)))
    KEEP (*(.dtors))
  } >RAM /* DATA-section */
  .jcr :
  {
    . = ALIGN(4);
    *(.jcr)
  } >RAM /* DATA-section */
  .got :
  {
    *(.got.plt) *(.got)
    _edata = .;
    PROVIDE (edata = .);
  } >RAM /* DATA-section */
  .based :
  {
    __tpbase = .;
    *(.based) *(.based.*) *(.gnu.linkonce.based.*)
    /* Assert maximum size */
    __assert_based_size = ASSERT ((. - __tpbase) <= 0x80,
	                          "based section overflow");
  } >RAM /* DATA-section */

  .bss       :
  {
    __bss_start = .;
    *(.dynbss)
    *(.bss)
    *(.bss.*)
    *(.gnu.linkonce.b.*)
    *(COMMON)
    /* Align here to ensure that the .bss section occupies space up to
      _end.  Align after .bss to ensure correct alignment even if the
      .bss section disappears because there are no input sections.  */
    . = ALIGN(32 / 8);
    _end = .;
    PROVIDE (end = .);
  } >RAM /* DATA-section */

  /* Sections to be placed in the code.m area.  */
  .init          : 
  { 
    KEEP (*(.init))
  } >RAM /* CODE-section */
  .plt      : { *(.plt)	} >RAM /* DATA-section */
  .text      :
  {
    *(.text)
    *(.text.*)
    *(.stub)
    /* .gnu.warning sections are handled specially by elf32.em.  */
    *(.gnu.warning)
    *(.gnu.linkonce.t.*)
  } >RAM /* CODE-section */ =0
  .vtext ALIGN(8)    :
  {
    *(.vtext)
  } >RAM /* CODE-section */
  .fini      :
  {
    KEEP (*(.fini))
    PROVIDE (__etext = .);
    PROVIDE (_etext = .);
    PROVIDE (etext = .);
  } >RAM /* CODE-section */ =0

  /* Sections to be placed in the romdata.m area.  */
  .rodata   : { *(.rodata) *(.rodata.*) *(.gnu.linkonce.r.*) } >RAM /* DATA-section */
  .rodata1   : { *(.rodata1) } >RAM /* DATA-section */

  /* Sections to be placed in the code.l area.  */
  .ftext : {  *(.ftext) *(.ftext.*) *(.gnu.linkonce.ft.*) } >RAM /* CODE-section */
  .vftext ALIGN(8)    :
  { 
    *(.vftext) *(.vftext.*) *(.gnu.linkonce.vf.*)
  } >RAM /* CODE-section */

  /* Sections to be placed in the romdata.l area.  */
  .frodata :
  {
    *(.frodata) *(.frodata.*) *(.gnu.linkonce.frd.*)
    __assert_near_size = ASSERT (. <= 0x1000000, "near section overflow");
  } >RAM /* DATA-section */

  /* Sections to be placed in the data.l area.  */
  .far : { *(.far) *(.far.*) *(.gnu.linkonce.far.*) } >RAM /* DATA-section */
  .farbss :
  { PROVIDE (__farbss_start = .);
    *(.farbss) *(.farbss.*)
    PROVIDE (__farbss_end = .);
  } >RAM /* DATA-section */

  /* END-mep-sections */

  /* begin-stack-table */
  __stack0  = (__stack - (0 *  (__stack_size / 1)) + 15) / 16 * 16;

  .rostacktab : 
  {
    /* Emit a table describing the location of the different stacks.
       Only 1 processor in the default configuration.  */
    . = ALIGN(4);
    __stack_table = .;
    LONG (__stack0);
    __stack_end = .;
  } >RAM
  /* end-stack-table */

  /* begin-heap */
  /* End of DATA is 0x00800000 + 0x00800000. That's where the heap will end.  */
  __heap_end = 0x00800000 + 0x00800000 - 1;
  /* end-heap */

  /* Default stack size is 1M.  That's where the heap will start if there's
     room.  If there's not enough room, allocate half of the remaining space
     for stack and half for heap.  Align the heap on a 16 byte boundary.  */
  __stack_size = (__stack_end + 0x100000 <= __heap_end + 1 
	          ? 0x100000
 		  : ((__heap_end + 1 - __stack_end) / 2));
  __heap = (__stack_end + __stack_size + 15) / 16 * 16;

  /* Leave 16 bytes between the stack and the heap.  */
  __stack = __heap - 0x10;

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
