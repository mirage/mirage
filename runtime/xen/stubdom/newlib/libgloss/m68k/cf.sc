# a linker script template.
# RAM - start of board's ram
# RAM_SIZE - size of board's ram
# ROM - start of board's rom
# ROM_SIZE - size of board's rom
# IO - io library name

test -z "${ROM:+1}" && NOROM=1

cat <<EOF
STARTUP(cf-${IO}-crt0.o)
OUTPUT_ARCH(m68k)
ENTRY(__start)
SEARCH_DIR(.)
GROUP(-lc -l${IO} -lcf)
__DYNAMIC  =  0;

MEMORY
{
  ${ROM:+rom (rx) : ORIGIN = ${ROM}, LENGTH = ${ROM_SIZE}}
  ram (rwx) : ORIGIN = ${RAM}, LENGTH = ${RAM_SIZE}
}

/* Place the stack at the end of memory, unless specified otherwise. */
PROVIDE (__stack = ${RAM} + ${RAM_SIZE});

SECTIONS
{
  .text :
  {
    CREATE_OBJECT_SYMBOLS
    *(.interrupt_vector)
    
    cf-${IO}-crt0.o(.text)
    *(.text .text.*)
    *(.gnu.linkonce.t.*)

    . = ALIGN(0x4);
    /* These are for running static constructors and destructors under ELF.  */
    KEEP (*crtbegin.o(.ctors))
    KEEP (*(EXCLUDE_FILE (*crtend.o) .ctors))
    KEEP (*(SORT(.ctors.*)))
    KEEP (*crtend.o(.ctors))
    KEEP (*crtbegin.o(.dtors))
    KEEP (*(EXCLUDE_FILE (*crtend.o) .dtors))
    KEEP (*(SORT(.dtors.*)))
    KEEP (*crtend.o(.dtors))

    . = ALIGN(0x4);
    KEEP (*crtbegin.o(.jcr))
    KEEP (*(EXCLUDE_FILE (*crtend.o) .jcr))
    KEEP (*crtend.o(.jcr))

    *(.rodata .rodata.*)
    *(.gnu.linkonce.r.*)

    . = ALIGN(0x4);
    *(.gcc_except_table) 

    . = ALIGN(0x4);
    *(.eh_frame)

    . = ALIGN(0x4);
    _init = . ;
    LONG (0x4e560000)	/* linkw %fp,#0 */
    *(.init)
    SHORT (0x4e5e)	/* unlk %fp */
    SHORT (0x4e75)	/* rts */

    . = ALIGN(0x4);
    _fini = . ;
    LONG (0x4e560000)	/* linkw %fp,#0 */
    *(.fini)
    SHORT (0x4e5e)	/* unlk %fp */
    SHORT (0x4e75)	/* rts */

    *(.lit)

    . = ALIGN(4);
    _etext = .;
  } >${ROM:+rom}${NOROM:+ram}

  .data :
  {
    __data_load = LOADADDR (.data);
    __data_start = .;
    *(.got.plt) *(.got)
    *(.shdata)
    *(.data .data.*)
    *(.gnu.linkonce.d.*)
    . = ALIGN (4);
    _edata = .;
  } >ram ${ROM:+AT>rom}

  .bss :
  {
    __bss_start = . ;
    *(.shbss)
    *(.bss .bss.*)
    *(.gnu.linkonce.b.*)
    *(COMMON)
    . = ALIGN (8);
    _end = .;
    __end = _end;
  } >ram ${ROM:+AT>rom}

  .stab 0 (NOLOAD) :
  {
    *(.stab)
  }

  .stabstr 0 (NOLOAD) :
  {
    *(.stabstr)
  }

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
  .debug_info     0 : { *(.debug_info .gnu.linkonce.wi.*) }
  .debug_abbrev   0 : { *(.debug_abbrev) }
  .debug_line     0 : { *(.debug_line) }
  .debug_frame    0 : { *(.debug_frame) }
  .debug_str      0 : { *(.debug_str) }
  .debug_loc      0 : { *(.debug_loc) }
  .debug_macinfo  0 : { *(.debug_macinfo) }

}
EOF
