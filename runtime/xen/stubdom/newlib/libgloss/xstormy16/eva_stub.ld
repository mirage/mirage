OUTPUT_FORMAT("elf32-xstormy16", "elf32-xstormy16",
	      "elf32-xstormy16")
OUTPUT_ARCH(xstormy16)
ENTRY(_start)

MEMORY 
{
  CPUDATA (!w) : ORIGIN = 0x7F00, LENGTH = 0x100
  ROM     (w)  : ORIGIN = 0x8000, LENGTH = 0x1000
}

/* Point interrupt vectors to user application. */
PROVIDE (_int_basetimer = 0x10004);
PROVIDE (_int_timer0 = 0x10008);
PROVIDE (_int_timer1 = 0x1000C);
PROVIDE (_int_sio0   = 0x10010);
PROVIDE (_int_sio1   = 0x10014);
PROVIDE (_int_port0  = 0x10018);
PROVIDE (_int_port1  = 0x1001C);

SECTIONS
{
  /* CPU data for Sanyo debugger */
  .cpudata :  { KEEP (*(.cpudata)) } > CPUDATA
  /* Read-only sections in ROM.  */
  .int_vec  : { *(.int_vec) } > ROM
  .rodata   : { *(.rodata) *(.rodata.*) *(.gnu.linkonce.r.*) } > ROM
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
  } > ROM
   .dtors         :
  {
    KEEP (*crtbegin.o(.dtors))
    KEEP (*(EXCLUDE_FILE (*crtend.o ) .dtors))
    KEEP (*(SORT(.dtors.*)))
    KEEP (*(.dtors))
  } > ROM
  .eh_frame : { KEEP (*(.eh_frame)) } > ROM
  .gcc_except_table : { *(.gcc_except_table) } > ROM
  .jcr : { *(.jcr) } > ROM
  .plt : { *(.plt) } > ROM
  .text      :
  {
    *(.text)
    *(.text.*)
    *(.stub)
    /* .gnu.warning sections are handled specially by elf32.em.  */
    *(.gnu.warning)
    *(.gnu.linkonce.t.*)
  } > ROM =0
  .init          : 
  { 
    KEEP (*(.init))
  } > ROM =0
  .fini      :
  {
    KEEP (*(.fini))
  } > ROM =0
  PROVIDE (__etext = .);
  PROVIDE (_etext = .);
  PROVIDE (etext = .);
  .data    :
  {
    __data = .;
    __rdata = .;
    *(.data)
    *(.data.*)
    *(.gnu.linkonce.d.*)
    SORT(CONSTRUCTORS)
  } > ROM
  _edata = .;
  PROVIDE (edata = .);
  __bss_start = .;
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
   . = ALIGN(2);
  } > ROM
  . = ALIGN(2);
  _end = .;
  PROVIDE (end = .);

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
