/* Linker script for the SH2 Low-Cost Eval Board. */

SEARCH_DIR(.)
GROUP(-lc -lgcc)
__DYNAMIC  =  0;

MEMORY
{
  ram (rwx) : ORIGIN = 0x4004000, LENGTH = 0x40000
}

/* Put the stack up high. */
/* (Commented out because it doesn't seem to work right) */
/*PROVIDE (__stack = 0x403ff00);*/

/* Initalize some symbols to be zero so we can reference them in the
   crt0 without core dumping. These functions are all optional, but
   we do this so we can have our crt0 always use them if they exist. 
   This is so BSPs work better when using the crt0 installed with gcc.
   We have to initalize them twice, so we cover a.out (which prepends
   an underscore) and coff object file formats. */

PROVIDE (hardware_init_hook = 0);
PROVIDE (_hardware_init_hook = 0);
PROVIDE (software_init_hook = 0);
PROVIDE (_software_init_hook = 0);

/* Put everything in ram (of course).  */

SECTIONS
{
  .text :
  {
    *(.text)
    . = ALIGN(0x4);
     __CTOR_LIST__ = .;
    LONG((__CTOR_END__ - __CTOR_LIST__) / 4 - 2)
    ___ctors = .;
    *(.ctors)
    ___ctors_end = .;
    LONG(0)
    __CTOR_END__ = .;
    __DTOR_LIST__ = .;
    LONG((__DTOR_END__ - __DTOR_LIST__) / 4 - 2)
    ___dtors = .;
    *(.dtors)
    ___dtors_end = .;
     LONG(0)
    __DTOR_END__ = .;
    *(.rodata)
    *(.gcc_except_table) 

     _etext = .;
    *(.lit)
  } > ram

  .data BLOCK (0x4) :
  {
    *(.shdata)
    *(.data)
    _edata = .;
  } > ram

  .bss BLOCK (0x4) :
  {
    __bss_start = . ;
    *(.shbss)
    *(.bss)
    *(COMMON)
    _end =  ALIGN (0x8);
    __end = _end;
  } > ram

  /* I know, I know, stack sections are supposed to be useless; but
     this actually worked for me, as opposed to the PROVIDE. */
  .stack 0x403ff00 :
  {
	__stack = .;
  } > ram

  .stab 0 (NOLOAD) : { *(.stab) }
  .stabstr 0 (NOLOAD) : { *(.stabstr) }

  /* DWARF debug sections.
     Symbols in the DWARF debugging sections are relative to 
     the beginning of the section so we begin them at 0.  */
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
  .debug_info     0 : { *(.debug_info) }
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
}
